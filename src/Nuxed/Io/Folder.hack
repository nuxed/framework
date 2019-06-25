namespace Nuxed\Io;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Regex;
use type Nuxed\Io\Exception\InvalidPathException;

final class Folder extends Node {
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
    $this->isAvailable();
    $ret = await parent::chgrp($group);
    if (!$recursive || false === $ret) {
      return $ret;
    }

    return await $this->chop(($node) ==> $node->chgrp($group, true));
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
    $this->isAvailable();
    $ret = await parent::chmod($mode);
    if (!$recursive || false === $ret) {
      return $ret;
    }

    return await $this->chop(($node) ==> $node->chmod($mode, true));
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
    $this->isAvailable();
    $ret = await parent::chown($user);
    if (!$recursive || false === $ret) {
      return $ret;
    }

    return await $this->chop(($node) ==> $node->chown($user, true));
  }

  private async function chop(
    (function(Node): Awaitable<bool>) $op,
  ): Awaitable<bool> {
    $iterator = new \DirectoryIterator($this->path->toString());
    $awaitables = vec[];
    foreach ($iterator as $node) {
      if ($node->isDot()) {
        continue;
      }

      $node = Node::load($node->getPathname());
      $awaitables[] = $op($node);
    }

    $ret = await Asio\v($awaitables);
    return C\reduce($ret, ($a, $b) ==> $a && $b, true);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function create(int $mode = 0755): Awaitable<bool> {
    if ($this->exists()) {
      throw new Exception\ExistingNodeException(
        Str\format('Folder (%s) already exists.', $this->path->toString()),
      );
    }

    $ret = @\mkdir($this->path->toString(), $mode, true) as bool;
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
  ): Awaitable<Folder> {
    $this->isAvailable();
    // Delete the target folder if overwrite is true
    if ($process === OperationType::OVERWRITE && $target->exists()) {
      await static::destroy($target);
    }

    // Create the target folder and reset folder path
    $destination = new Folder($target, true, $mode);
    $target = $destination->path();

    // Recursively copy over contents to new destination
    $contents = await $this->list(false, true, Node::class);

    $awaitables = vec[];
    foreach ($contents as $node) {
      $to = Path::create(Str\replace(
        $node->path()->toString(),
        $this->path->toString(),
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
    $this->reset();
    return $destination;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function delete(): Awaitable<bool> {
    $this->isAvailable();
    await $this->flush();
    $deleted = @\rmdir($this->path->toString()) as bool;
    $this->reset();
    return $deleted;
  }

  /**
   * Recursively delete all files and folders within this folder.
   */
  public async function flush(): Awaitable<this> {
    $this->isAvailable();
    $this->isReadable();

    // delete files first.
    $files = await $this->files(false, true);
    await Asio\v(Vec\map(
      $files,
      ($node) ==> $node->exists()
        ? $node->delete()
        : async {
            return false;
          },
    ));

    // delete rest of the nodes.
    $nodes = await $this->list(false, true, Node::class);
    await Asio\v(Vec\map(
      $nodes,
      ($node) ==> $node->exists()
        ? $node->delete()
        : async {
            return false;
          },
    ));
    return $this;
  }

  /**
   * Find all files and folders within the current folder that match a specific regex pattern.
   */
  public async function find<Tr as Regex\Match>(
    Regex\Pattern<Tr> $pattern,
    bool $recursive = false,
  ): Awaitable<Container<Node>> {
    return Vec\filter(
      await $this->list(true, $recursive, Node::class),
      ($node) ==> Regex\matches(
        $this->path()->relativeTo($node->path())
          |> $$->toString()
          |> Str\slice($$, 2)
          |> Str\trim_right($$, '/'),
        $pattern,
      ),
    );
  }

  /**
   * Scan the folder and return a list of File objects.
   */
  public function files(
    bool $sort = false,
    bool $recursive = false,
  ): Awaitable<Container<File>> {
    return $this->list($sort, $recursive, File::class);
  }

  /**
   * Scan the folder and return a list of Folder objects.
   */
  public function folders(
    bool $sort = false,
    bool $recursive = false,
  ): Awaitable<Container<Folder>> {
    return $this->list($sort, $recursive, Folder::class);
  }

  /**
   * Scan the folder and return a list of File and Folder objects.
   */
  public async function list<T as Node>(
    bool $sort = false,
    bool $recursive = false,
    ?classname<T> $filter = null,
  ): Awaitable<Container<T>> {
    $this->isAvailable();
    $this->isReadable();

    try {
      $directory = $this->path->toString();
      $flags = \FilesystemIterator::SKIP_DOTS |
        \FilesystemIterator::UNIX_PATHS |
        \FilesystemIterator::NEW_CURRENT_AND_KEY;

      $iterator = new \FilesystemIterator($directory, $flags);
    } catch (\Exception $e) {
      throw new Exception\ReadErrorException(
        Str\format(
          'Error while reading from folder (%s).',
          $this->path->toString(),
        ),
        $e->getCode(),
        $e,
      );
    }

    /**
     * @link https://github.com/facebook/hhvm/issues/8090
     */
    $filter ??= Node::class;
    $contents = vec[];
    $awaitables = vec[];
    foreach ($iterator as $node) {
      if (
        $node->isDir() && ($filter === Node::class || $filter === Folder::class)
      ) {
        $contents[] = new Folder(Path::create($node->getPathname()));
      } else if (
        $node->isFile() && ($filter === Node::class || $filter === File::class)
      ) {
        $contents[] = new File(Path::create($node->getPathname()));
      }

      if ($node->isDir() && $recursive) {
        $folder = new Folder($node->getPathname());
        $awaitables[] = $folder->list(false, true, $filter);
      }
    }

    $inner = await Asio\v($awaitables);
    $contents = Vec\concat($contents, ...$inner);

    if ($sort) {
      $contents = Vec\sort(
        $contents,
        (Node $a, Node $b) ==> $a->path()->compare($b->path()),
      );
    }

    /* HH_FIXME[4110] */
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
    $this->isAvailable();
    if ($target->compare($this->path) === 0) {
      return true; // Don't move to the same location
    }

    return await parent::move($target, $overwrite);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function reset(Path $path = $this->path): this {
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
    $this->isAvailable();
    $nodes = await $this->list(false, true, Node::class);
    return C\count($nodes);
  }

  /**
   * Create a file with the given name inside the current directory.
   *
   * @param int $mode file mode.
   */
  public async function touch(string $file, int $mode = 0755): Awaitable<File> {
    $this->isAvailable();
    $this->isWritable();

    $path = Path::create(Str\format('%s/%s', $this->path->toString(), $file));
    if ($path->exists()) {
      throw new Exception\ExistingNodeException(
        Str\format('File (%s) already exist.', $path->toString()),
      );
    }

    $file = new File($path, false);
    await $file->create($mode);
    return $file;
  }

  /**
   * Create a folder with the given name insde the current directory.
   *
   * @param int $mode folder mode.
   */
  public async function mkdir(
    string $folder,
    int $mode = 0755,
  ): Awaitable<Folder> {
    $this->isAvailable();
    $this->isWritable();

    $path = Path::create(Str\format('%s/%s', $this->path->toString(), $folder));
    if ($path->exists()) {
      throw new Exception\ExistingNodeException(
        Str\format('Folder (%s) already exist.', $path->toString()),
      );
    }

    $folder = new Folder($path, false);
    await $folder->create($mode);
    return $folder;
  }

  /**
   * Remove a node insde the current folder.
   */
  public async function remove(string $node): Awaitable<bool> {
    $node = await $this->read($node, Node::class);
    return await $node->delete();
  }

  /**
   * Return true if a child node with the given name exists.
   */
  public function contains(string $node): bool {
    return Path::create(Str\format('%s/%s', $this->path->toString(), $node))
      ->exists();
  }

  /**
   * Read a node from the current directory.
   */
  public async function read<T as Node>(
    string $name,
    ?classname<T> $filter = null,
  ): Awaitable<T> {
    $this->isAvailable();
    $path = Path::create(Str\format('%s/%s', $this->path->toString(), $name));
    $node = Node::load($path);
    $filter ??= Node::class;
    if (
      ($filter === File::class && $node is Folder) ||
      ($filter === Folder::class && $node is File)
    ) {
      throw new Exception\InvalidPathException(Str\format(
        'Invalid %s path (%s), %s are not allowed.',
        Str\lowercase($filter),
        $path->toString(),
        $node is Folder ? 'folders' : 'files',
      ));
    }

    /* HH_FIXME[4110] */
    return $node;
  }
}
