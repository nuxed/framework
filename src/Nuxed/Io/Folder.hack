namespace Nuxed\Io;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use type Nuxed\Io\Exception\InvalidPathException;
use type Exception;
use type GlobIterator;
use type FilesystemIterator;
use type RecursiveDirectoryIterator;
use type RecursiveIteratorIterator;
use function file_exists;
use function mkdir;
use function is_file;
use function unlink;
use function rmdir;
use function clearstatcache;

final class Folder extends Node {

  const ALL = 0;
  const FILES = 1;
  const FOLDERS = 2;

  /**
   * Change directory. Alias for reset().
   */
  public function cd(string $path): this {
    return $this->reset($path);
  }

  /**
   * Change the group of the file.
   * If $recursive is true, set the group on all children.
   */
  <<__Override>>
  public async function chgrp(
    int $group,
    bool $recursive = false,
  ): Awaitable<bool> {
    if ($recursive) {
      $contents = await $this->read();
      $awaitables = vec[];
      foreach ($contents as $file) {
        $awaitables[] = $file->chgrp($group, true);
      }
      await Asio\v($awaitables);
    }

    return await parent::chgrp($group);
  }

  /**
   * Change the permissions mode of the file.
   * If $recursive is true, set the mode on all children.
   */
  <<__Override>>
  public async function chmod(
    int $mode,
    bool $recursive = false,
  ): Awaitable<bool> {
    if ($recursive) {
      $contents = await $this->read();
      $awaitables = vec[];
      foreach ($contents as $file) {
        $awaitables[] = $file->chmod($mode, true);
      }
      await Asio\v($awaitables);
    }

    return await parent::chmod($mode);
  }

  /**
   * Change the owner of the file.
   * If $recursive is true, set the owner on all children.
   */
  <<__Override>>
  public async function chown(
    int $user,
    bool $recursive = false,
  ): Awaitable<bool> {
    if ($recursive) {
      $contents = await $this->read();
      $awaitables = vec[];
      foreach ($contents as $file) {
        $awaitables[] = $file->chown($user, true);
      }
      await Asio\v($awaitables);
    }

    return await parent::chown($user);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function create(int $mode = 0755): Awaitable<bool> {
    $ret = false;
    if (!$this->exists()) {
      $ret = (bool)@mkdir($this->path()->toString(), $mode, true);
    }
    $this->reset();

    return $ret;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function copy(
    string $target,
    OperationType $process = OperationType::MERGE,
    int $mode = 0755,
  ): Awaitable<?Folder> {
    if (!$this->exists()) {
      return null;
    }

    // Delete the target folder if overwrite is true
    if ($process === OperationType::OVERWRITE && file_exists($target)) {
      await static::destroy($target);
    }

    // Create the target folder and reset folder path
    $destination = new Folder($target, true, $mode);
    $target = $destination->path();

    // Recursively copy over contents to new destination
    $contents = await $this->read();

    $awaitables = vec[];
    foreach ($contents as $file) {
      $to = Str\replace(
        $file->path()->toString(),
        $this->path()->toString(),
        $target->toString(),
      );

      // Skip copy if target exists
      if ($process === OperationType::SKIP && file_exists($to)) {
        continue;
      }

      // Delete target since File::copy() will throw exception
      if (
        $process === OperationType::MERGE && file_exists($to) && is_file($to)
      ) {
        @unlink($to);
      }

      $awaitables[] = $file->copy($to, $process, $mode);
    }

    await Asio\v($awaitables);
    clearstatcache();
    return $destination;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function delete(): Awaitable<bool> {
    if (!$this->exists()) {
      return false;
    }
    await $this->flush();
    $this->reset();
    return rmdir($this->path()->toString());
  }

  /**
   * Recursively delete all files and folders within this folder.
   */
  public async function flush(): Awaitable<this> {
    $nodes = await $this->read(false, true);
    await Asio\v(Vec\map($nodes, ($node) ==> $node->delete()));
    return $this;
  }

  /**
   * Find all files and folders within the current folder that match a specific pattern.
   */
  public async function find<T super Node>(
    string $pattern,
    classname<T> $filter = Node::class,
  ): Awaitable<Container<T>> {
    $contents = vec[];

    if (!$this->exists()) {
      return $contents;
    }

    try {
      $iterator = new GlobIterator(
        $this->path().$pattern,
        FilesystemIterator::SKIP_DOTS | FilesystemIterator::UNIX_PATHS,
      );
    } catch (Exception $e) {
      return $contents;
    }

    foreach ($iterator as $file) {
      if (
        $file->isDir() && ($filter === Node::class || $filter === Folder::class)
      ) {
        $contents[] = new Folder($file->getPathname());

      } else if (
        $file->isFile() && ($filter === Node::class || $filter === File::class)
      ) {
        $contents[] = new File($file->getPathname());
      }
    }

    return $contents;
  }

  /**
   * Scan the folder and return a list of File objects.
   */
  public function files(
    bool $sort = false,
    bool $recursive = false,
  ): Awaitable<Container<File>> {
    return $this->read($sort, $recursive, File::class);
  }

  /**
   * Scan the folder and return a list of Folder objects.
   */
  public function folders(
    bool $sort = false,
    bool $recursive = false,
  ): Awaitable<Container<Folder>> {
    return $this->read($sort, $recursive, Folder::class);
  }

  /**
   * Scan the folder and return a list of File and Folder objects.
   */
  public async function read<T as Node>(
    bool $sort = false,
    bool $recursive = false,
    ?classname<T> $filter = null,
  ): Awaitable<Container<T>> {
    $filter = $filter ?? Node::class;

    $contents = vec[];
    if (!$this->exists()) {
      return $contents;
    }

    try {
      $flags = FilesystemIterator::SKIP_DOTS | FilesystemIterator::UNIX_PATHS;

      if ($recursive) {
        $iterator = new RecursiveIteratorIterator(
          new RecursiveDirectoryIterator($this->path(), $flags),
          RecursiveIteratorIterator::CHILD_FIRST,
        );
      } else {
        $iterator = new FilesystemIterator($this->path(), $flags);
      }
    } catch (Exception $e) {
      return $contents;
    }

    foreach ($iterator as $file) {
      if (
        $file->isDir() && ($filter === Node::class || $filter === Folder::class)
      ) {
        $contents[] = new Folder($file->getPathname());

      } else if (
        $file->isFile() && ($filter === Node::class || $filter === File::class)
      ) {
        $contents[] = new File($file->getPathname());
      }
    }

    if ($sort) {
      $contents = Vec\sort(
        $contents,
        (Node $a, Node $b) ==>
          Str\compare($a->path()->toString(), $b->path()->toString()),
      );
    }

    // UNSAFE
    return $contents;
  }


  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function move(
    string $target,
    bool $overwrite = true,
  ): Awaitable<bool> {
    if (
      Path::normalize($target) === Path::normalize($this->path()->toString())
    ) {
      return true; // Don't move to the same location
    }

    return await parent::move($target, $overwrite);
  }

  /**
   * {@inheritdoc}
   *
   * @throws InvalidPathException
   */
  <<__Override>>
  public function reset(string $path = ''): this {
    if ('' !== $path) {
      if (file_exists($path) && is_file($path)) {
        throw new InvalidPathException(
          Str\format('Invalid folder path %s, files are not allowed', $path),
        );
      }

      if (!Str\ends_with($path, '/')) {
        $path .= '/';
      }
    }

    return parent::reset($path);
  }

  /**
   * Return the number of files in the current folder.
   */
  <<__Override>>
  public async function size(): Awaitable<int> {
    if ($this->exists()) {
      $nodes = await $this->read();
      return C\count($nodes);
    }

    return 0;
  }

}
