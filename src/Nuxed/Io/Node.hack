namespace Nuxed\Io;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace HH\Lib\Regex;
use type Nuxed\Io\Exception\MissingFileException;
use type Nuxed\Io\Exception\ExistingFileException;
use function is_writable;
use function is_readable;
use function is_executable;
use function rename;
use function basename;
use function clearstatcache;
use function fileatime;
use function filectime;
use function filegroup;
use function filemtime;
use function fileowner;
use function fileperms;
use function pathinfo;
use function chgrp;
use function chmod;
use function chown;
use function lchgrp;
use function lchown;
use const PATHINFO_BASENAME;
use const PATHINFO_FILENAME;

/**
 * Shared functionality between file and folder objects.
 */
<<__Sealed(File::class, Folder::class)>>
abstract class Node {
  /**
   * Parent folder.
   */
  protected ?Folder $parent;

  /**
   * Initialize the file path. If the file doesn't exist, create it.
   */
  public function __construct(
    protected Path $path,
    bool $create = false,
    int $mode = 0755,
  ) {
    $this->reset($path);

    if ($create) {
      Asio\join($this->create($mode));
    }
  }

  /**
   * Return the last access time.
   */
  public function accessTime(): int {
    if ($this->exists()) {
      return fileatime($this->path()->toString());
    }

    return 0;
  }

  /**
   * Return the file name with extension.
   */
  public function basename(): string {
    return pathinfo($this->path()->toString(), PATHINFO_BASENAME);
  }

  /**
   * Return the last inode change time.
   */
  public function changeTime(): int {
    if ($this->exists()) {
      return filectime($this->path()->toString());
    }

    return 0;
  }

  /**
   * Change the group of the file.
   */
  public async function chgrp(
    int $group,
    bool $_recursive = false,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      return false;
    }

    $path = $this->path();

    $this->reset();

    if ($path->isSymlink()) {
      return lchgrp($path->toString(), $group);
    }

    return chgrp($path->toString(), $group);
  }

  /**
   * Change the permissions mode of the file.
   */
  public async function chmod(
    int $mode,
    bool $_recursive = false,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      return false;
    }

    $this->reset();

    return chmod($this->path()->toString(), $mode);
  }

  /**
   * Change the owner of the file.
   */
  public async function chown(
    int $user,
    bool $_recursive = false,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      return false;
    }

    $path = $this->path();

    $this->reset();

    if ($path->isSymlink()) {
      return lchown($path->toString(), $user);
    }

    return chown($path->toString(), $user);
  }

  /**
   * Copy the file to a new location and return a new Node object.
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
  ): Awaitable<?Node>;

  /**
   * Create the node if it doesn't exist.
   */
  abstract public function create(int $mode = 0755): Awaitable<bool>;

  /**
   * Remove the node if it exists.
   */
  abstract public function delete(): Awaitable<bool>;

  /**
   * Helper method for deleting a file or folder.
   */
  public static async function destroy(Path $path): Awaitable<bool> {
    if (!$path->exists()) {
      return false;
    }

    return await static::load($path)->delete();
  }

  /**
   * Return the parent directory as a string.
   * Will always end in a trailing slash.
   */
  public function dir(): Path {
    $dir = $this->path()->parent()->toString().'/';
    return Path::create($dir);
  }

  /**
   * Is the file executable.
   */
  public function executable(): bool {
    return is_executable($this->path()->toString());
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
    if ($this->exists()) {
      return filegroup($this->path()->toString()) as int;
    }

    return 0;
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
  public static function load(Path $path): Node {
    if (!$path->exists()) {
      throw new MissingFileException(
        Str\format('No file or folder found at %s', $path->toString()),
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
    if ($this->exists()) {
      return filemtime($this->path()->toString());
    }

    return 0;
  }

  /**
   * Move the file to another folder. If a file exists at the target path,
   * either delete the file if `$overwrite` is true, or throw an exception.
   *
   * Use `rename()` to rename the file within the current folder.
   *
   * @throws ExistingFileException
   */
  public async function move(
    Path $target,
    bool $overwrite = true,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      return false;
    }

    // Don't move if the target exists and overwrite is disabled
    if ($target->exists()) {
      if ($overwrite) {
        await static::destroy($target);
      } else {
        throw new ExistingFileException(
          'Cannot move file as the target already exists',
        );
      }
    }

    // Move folders
    if (rename($this->path()->toString(), $target->toString())) {
      $this->reset($target);

      return true;
    }

    return false;
  }

  /**
   * Return the file name without extension.
   */
  public function name(): string {
    return pathinfo($this->path()->toString(), PATHINFO_FILENAME);
  }

  /**
   * Return the owner name for the file.
   */
  public function owner(): int {
    if ($this->exists()) {
      return fileowner($this->path()->toString());
    }

    return 0;
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
   * Return the permissions for the file.
   */
  public function permissions(): ?int {
    if ($this->exists()) {
      return fileperms($this->path()->toString()) & 0777;
    }

    return null;
  }

  /**
   * Return the current path (print working directory).
   */
  public function pwd(): Path {
    return $this->path;
  }

  /**
   * Is the file readable.
   */
  public function readable(): bool {
    return is_readable($this->path()->toString());
  }

  /**
   * Rename the file within the current folder. If a file exists at the target path,
   * either delete the file if `$overwrite` is true, or throw an exception.
   *
   * Use `move()` to re-locate the file to another folder.
   *
   * @throws ExistingFileException
   */
  public async function rename(
    string $name,
    bool $overwrite = true,
  ): Awaitable<bool> {
    if (!$this->exists()) {
      return false;
    }

    // Remove unwanted characters
    $name = Regex\replace(
      basename($name),
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
        throw new ExistingFileException(
          'Cannot rename file as the target already exists',
        );
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
  public function reset(Path $path = Path::create('')): this {
    if ('' !== $path->toString()) {
      $this->path = $path;
    }

    clearstatcache();

    return $this;
  }

  /**
   * Return the current file size.
   */
  abstract public function size(): Awaitable<int>;

  /**
   * Is the file writable.
   */
  public function writable(): bool {
    return is_writable($this->path()->toString());
  }
}
