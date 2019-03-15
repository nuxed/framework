namespace Nuxed\Io;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use type Nuxed\Io\Exception\InvalidPathException;
use type Iterator;
use type Exception;
use type SplFileInfo;
use type GlobIterator;
use type IteratorAggregate;
use type FilesystemIterator;
use type RecursiveIteratorIterator;
use type RecursiveDirectoryIterator;
use function mkdir;
use function rmdir;
use function clearstatcache;

final class Folder extends Node implements IteratorAggregate<Node> {
  /**
   * Change directory. Alias for reset().
   */
  public function cd(Path $path): this {
    return $this->reset($path);
  }

  /**
   * Change the group of the folder.
   * If $recursive is true, set the group on all children.
   */
  <<__Override>>
  public async function chgrp(
    int $group,
    bool $recursive = false,
  ): Awaitable<bool> {
    if ($recursive) {
      $contents = await $this->read(false, true, Node::class);
      $awaitables = vec[];
      foreach ($contents as $node) {
        $awaitables[] = $node->chgrp($group, true);
      }

      await Asio\v($awaitables);
    }

    return await parent::chgrp($group);
  }

  /**
   * Change the permissions mode of the folder.
   * If $recursive is true, set the mode on all children.
   */
  <<__Override>>
  public async function chmod(
    int $mode,
    bool $recursive = false,
  ): Awaitable<bool> {
    if ($recursive) {
      $contents = await $this->read(false, true, Node::class);
      $awaitables = vec[];
      foreach ($contents as $node) {
        $awaitables[] = $node->chmod($mode, true);
      }

      await Asio\v($awaitables);
    }

    return await parent::chmod($mode);
  }

  /**
   * Change the owner of the folder.
   * If $recursive is true, set the owner on all children.
   */
  <<__Override>>
  public async function chown(
    int $user,
    bool $recursive = false,
  ): Awaitable<bool> {
    if ($recursive) {
      $contents = await $this->read(false, true, Node::class);
      $awaitables = vec[];
      foreach ($contents as $node) {
        $awaitables[] = $node->chown($user, true);
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
    Path $target,
    OperationType $process = OperationType::MERGE,
    int $mode = 0755,
  ): Awaitable<?Folder> {
    if (!$this->exists()) {
      return null;
    }

    // Delete the target folder if overwrite is true
    if ($process === OperationType::OVERWRITE && $target->exists()) {
      await static::destroy($target);
    }

    // Create the target folder and reset folder path
    $destination = new Folder($target, true, $mode);
    $target = $destination->path();

    // Recursively copy over contents to new destination
    $contents = await $this->read(false, true, Node::class);

    $awaitables = vec[];
    foreach ($contents as $node) {
      $to = Path::create(Str\replace(
        $node->path()->toString(),
        $this->path()->toString(),
        $target->toString(),
      ));

      // Skip copy if target exists
      if ($process === OperationType::SKIP && $to->exists()) {
        continue;
      }

      $destroy = async {
      };
      // Delete target since File::copy() will throw exception
      if ($process === OperationType::MERGE && $to->exists() && $to->isFile()) {
        $destroy = Node::destroy($to);
      }

      $awaitables[] = async {
        await $destroy;
        await $node->copy($to, $process, $mode);
      };
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
    return @rmdir($this->path()->toString());
  }

  /**
   * Recursively delete all files and folders within this folder.
   */
  public async function flush(): Awaitable<this> {
    // delete files first.
    $files = await $this->files(false, true);
    await Asio\v(Vec\map($files, ($file) ==> $file->delete()));
    // delete rest of the nodes.
    $nodes = await $this->read(false, true, Node::class);
    await Asio\v(Vec\map($nodes, ($node) ==> $node->delete()));
    return $this;
  }

  /**
   * Find all files and folders within the current folder that match a specific pattern.
   */
  public async function find<T as Node>(
    string $pattern,
    ?classname<T> $filter = null,
  ): Awaitable<Container<T>> {
    $filter ??= Node::class;

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
        $contents[] = new Folder(Path::create($file->getPathname()));

      } else if (
        $file->isFile() && ($filter === Node::class || $filter === File::class)
      ) {
        $contents[] = new File(Path::create($file->getPathname()));
      }
    }

    // UNSAFE
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
    $filter ??= Node::class;

    $contents = vec[];
    if (!$this->exists()) {
      return $contents;
    }

    try {
      $directory = $this->path()->toString();
      $flags = FilesystemIterator::SKIP_DOTS |
        FilesystemIterator::UNIX_PATHS |
        FilesystemIterator::NEW_CURRENT_AND_KEY;

      if ($recursive) {
        $iterator = new RecursiveIteratorIterator(
          new RecursiveDirectoryIterator($directory, $flags),
          RecursiveIteratorIterator::CHILD_FIRST,
        );
      } else {
        $iterator = new FilesystemIterator($directory, $flags);
      }
    } catch (Exception $e) {
      return $contents;
    }

    $iterator->rewind();
    while ($iterator->valid()) {
      $file = $iterator->current() as SplFileInfo;
      if (
        $file->isDir() && ($filter === Node::class || $filter === Folder::class)
      ) {
        $contents[] = new Folder(Path::create($file->getPathname()));
      } elseif (
        $file->isFile() && ($filter === Node::class || $filter === File::class)
      ) {
        $contents[] = new File(Path::create($file->getPathname()));
      }

      $iterator->next();
    }

    if ($sort) {
      $contents = Vec\sort(
        $contents,
        (Node $a, Node $b) ==> $a->path()->compare($b->path()),
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
    Path $target,
    bool $overwrite = true,
  ): Awaitable<bool> {
    if ($target->compare($this->path()) === 0) {
      return true; // Don't move to the same location
    }

    return await parent::move($target, $overwrite);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function reset(Path $path = $this->path()): this {
    if ($path->exists() && $path->isFile()) {
      throw new InvalidPathException(
        Str\format(
          'Invalid folder path (%s), files are not allowed',
          $path->toString(),
        ),
      );
    }

    return parent::reset($path);
  }

  /**
   * Return the number of files in the current folder.
   */
  <<__Override>>
  public async function size(): Awaitable<int> {
    if ($this->exists()) {
      $nodes = await $this->read(false, true, Node::class);
      return C\count($nodes);
    }

    return 0;
  }

  public async function touch(
    string $file,
    int $mode = 0755,
  ): Awaitable<?File> {
    if (!$this->exists()) {
      return null;
    }

    $path = Path::create(Str\format('%s/%s', $this->path()->toString(), $file));

    if ($path->exists()) {
      throw new Exception\ExistingFileException(
        Str\format('File (%s) already exist.', $path->toString()),
      );
    }

    $file = new File($path, false);
    await $file->create($mode);
    return $file;
  }

  public function getIterator(): Iterator<Node> {
    $nodes = new Vector(Asio\join($this->read(true, true)));
    return $nodes->getIterator();
  }
}
