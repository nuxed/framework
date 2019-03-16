namespace Nuxed\Io;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace HH\Lib\Regex;
use type Stringish;
use function is_writable;
use function is_readable;
use function is_executable;
use function rename;
use function clearstatcache;
use function fileatime;
use function filectime;
use function filegroup;
use function filemtime;
use function fileowner;
use function fileperms;
use function chgrp;
use function chmod;
use function chown;
use function lchgrp;
use function lchown;

/**
 * Shared functionality between file and folder objects.
 */
<<__Sealed(File::class, Folder::class)>>
abstract class Node {
  /**
   * Parent folder.
   */
  protected ?Folder $parent;

  protected Path $path;

  /**
   * Initialize the node path. If the node doesn't exist and `$create` is true, create it.
   */
  public function __construct(
    Stringish $path,
    bool $create = false,
    int $mode = 0755,
  ) {
    $this->path = $this->normalizePath(Path::create($path));
    $this->reset($this->path);
    if ($create && !$this->path->exists()) {
      Asio\join($this->create($mode));
    }
  }

  /**
   * Return the last access time.
   */
  public function accessTime(): int {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    return fileatime($this->path()->toString()) as int;
  }

  /**
   * Return the node name with extension.
   */
  public function basename(): string {
    return $this->path()->basename();
  }

  /**
   * Return the last inode change time.
   */
  public function changeTime(): int {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    return filectime($this->path()->toString()) as int;
  }

  /**
   * Change the group of the node.
   */
  public async function chgrp(
    int $group,
    bool $_recursive = false,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    $path = $this->path();

    $this->reset();

    if ($path->isSymlink()) {
      return lchgrp($path->toString(), $group) as bool;
    }

    return chgrp($path->toString(), $group) as bool;
  }

  /**
   * Change the permissions mode of the node.
   */
  public async function chmod(
    int $mode,
    bool $_recursive = false,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    $this->reset();

    return chmod($this->path()->toString(), $mode) as bool;
  }

  /**
   * Change the owner of the node.
   */
  public async function chown(
    int $user,
    bool $_recursive = false,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    $path = $this->path();

    $this->reset();

    if ($path->isSymlink()) {
      return lchown($path->toString(), $user) as bool;
    }

    return chown($path->toString(), $user) as bool;
  }

  /**
   * Copy the node to a new location and return a new Node object.
   * The functionality of copy will change depending on `$process` and whether the target file exists.
   * This also applies recursively.
   *
   *      overwrite   - Will delete the target file or folder
   *      merge       - Will delete the target file and merge folders
   *      skip        - Will not copy the node if the target exists
   */
  abstract public function copy(
    Path $target,
    OperationType $process = OperationType::OVERWRITE,
    int $mode = 0755,
  ): Awaitable<Node>;

  /**
   * Create the node.
   */
  abstract public function create(int $mode = 0755): Awaitable<bool>;

  /**
   * Remove the node if it exists.
   */
  abstract public function delete(): Awaitable<bool>;

  /**
   * Helper method for deleting a file or folder.
   */
  public static async function destroy(Stringish $path): Awaitable<bool> {
    $path = Path::create($path);
    if (!$path->exists()) {
      throw new Exception\MissingNodeException(
        Str\format('Node (%s) doesn\'t exist.', $path->toString()),
      );
    }

    return await static::load($path)->delete();
  }

  /**
   * Return the parent directory.
   */
  public function dir(): Path {
    return $this->path()->parent();
  }

  /**
   * Is the file executable.
   */
  public function executable(): bool {
    return is_executable($this->path()->toString()) as bool;
  }

  /**
   * Check if the file exists.
   */
  public function exists(): bool {
    return $this->path()->exists();
  }

  /**
   * Return the group name for the file.
   */
  public function group(): int {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    return filegroup($this->path()->toString()) as int;
  }

  /**
   * Return true if the current path is absolute.
   */
  public function isAbsolute(): bool {
    return $this->path()->isAbsolute();
  }

  /**
   * Return true if the current path is relative.
   */
  public function isRelative(): bool {
    return $this->path()->isRelative();
  }

  /**
   * Attempt to load a file or folder object at a target location.
   */
  final public static function load(Stringish $path): Node {
    $path = Path::create($path);
    if (!$path->exists()) {
      throw new Exception\MissingNodeException(
        Str\format('Node (%s) doesn\'t exist.', $path->toString()),
      );
    }

    if ($path->isDirectory()) {
      return new Folder($path);
    }

    return new File($path);
  }

  /**
   * Return the last modified time.
   */
  public function modifyTime(): int {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    return filemtime($this->path()->toString()) as int;
  }

  /**
   * Move the node to another folder. If a node exists at the target path,
   * either delete the node if `$overwrite` is true, or throw an exception.
   *
   * Use `rename()` to rename the node within the current folder.
   *
   * @throws ExistingFileException
   */
  public async function move(
    Path $target,
    bool $overwrite = true,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    // Don't move if the target exists and overwrite is disabled
    if ($target->exists()) {
      if ($overwrite) {
        await static::destroy($target);
      } else {
        throw new Exception\ExistingNodeException(Str\format(
          'Cannot move %s (%s) as the target (%s) already exists.',
          $this is Folder ? 'folder' : 'file',
          $this->path()->toString(),
          $target->toString(),
        ));
      }
    }

    // Move node
    $moved = rename($this->path()->toString(), $target->toString()) as bool;
    if ($moved) {
      $this->reset($target);
    }

    return $moved;
  }

  /**
   * Return the node name without extension.
   */
  public function name(): string {
    return $this->path()->name();
  }

  /**
   * Return the owner name for the node.
   */
  public function owner(): int {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    return fileowner($this->path()->toString()) as int;
  }

  /**
   * Alias for pwd().
   */
  public function path(): Path {
    return $this->pwd();
  }

  /**
   * Return the parent folder as a Folder object.
   */
  public function parent(): ?Folder {
    if ($this->parent is nonnull) {
      return $this->parent;
    }

    $folder = $this->path()->parent();

    if ($folder->toString() !== '.' && $folder->toString() !== '/') {
      $this->parent = new Folder($folder);
    }

    return $this->parent;
  }

  /**
   * Return the permissions for the node.
   */
  public function permissions(): int {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    return fileperms($this->path()->toString()) & 0777;
  }

  /**
   * Return the current path (print working directory).
   */
  public function pwd(): Path {
    return $this->path;
  }

  /**
   * Is the node readable.
   */
  public function readable(): bool {
    return is_readable($this->path()->toString());
  }

  /**
   * Rename the node within the current folder. If a node exists at the target path,
   * either delete the node if `$overwrite` is true, or throw an exception.
   *
   * Use `move()` to re-locate the node to another folder.
   *
   * @throws ExistingFileException
   */
  public async function rename(
    string $name,
    bool $overwrite = true,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      throw new Exception\MissingNodeException(Str\format(
        '%s (%s) doesn\'t exist.',
        $this is Folder ? 'Folder' : 'File',
        $this->path()->toString(),
      ));
    }

    // Remove unwanted characters
    $name = Regex\replace(
      Path::create($name)->basename(),
      re"/[^_\-\p{Ll}\p{Lm}\p{Lo}\p{Lt}\p{Lu}\p{Nd}]/imu",
      '-',
    );

    // Return early if the same name
    if ($name === $this->name()) {
      return true;
    }

    // Prepend folder
    $target = Path::create($this->dir()->toString().$name);

    // Don't move if the target exists and overwrite is disabled
    if ($target->exists()) {
      if ($overwrite) {
        await static::destroy($target);
      } else {
        throw new Exception\ExistingNodeException(Str\format(
          'Cannot rename file as the target (%s) already exists.',
          $target->toString(),
        ));
      }
    }

    // Rename the file within the current folder
    if (rename($this->path()->toString(), $target->toString())) {
      $this->reset($target);

      return true;
    }

    return false;
  }

  /**
   * Reset the cache and path.
   */
  public function reset(Path $path = $this->path): this {
    $this->path = $this->normalizePath($path);
    clearstatcache();

    return $this;
  }

  /**
   * Return the current node size.
   */
  abstract public function size(): Awaitable<int>;

  /**
   * Is the node writable.
   */
  public function writable(): bool {
    return is_writable($this->path()->toString());
  }

  /**
   * Return the path normalized if it exists.
   */
  private function normalizePath(Path $path): Path {
    if ($path->exists() && !$path->isSymlink()) {
      return Path::create(Path::normalize($path->toString()) as string);
    }

    return $path;
  }
}
