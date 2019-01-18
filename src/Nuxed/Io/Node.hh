<?hh // strict

namespace Nuxed\Io;

use namespace HH\Lib\Str;
use type Nuxed\Io\Exception\MissingFileException;
use type Nuxed\Io\Exception\ExistingFileException;
use function is_dir;
use function is_writable;
use function is_readable;
use function is_link;
use function is_executable;
use function dirname;
use function rename;
use function basename;
use function preg_replace;
use function clearstatcache;
use function fileatime;
use function filectime;
use function filegroup;
use function filemtime;
use function fileowner;
use function fileperms;
use function file_exists;
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
 *
 * @package Nuxed\Io
 */
abstract class Node {

  const int OVERWRITE = 0;
  const int MERGE = 1;
  const int SKIP = 2;

  /**
   * Parent folder.
   */
  protected ?Folder $parent;

  /**
   * Current path.
   */
  protected string $path = '';

  /**
   * Initialize the file path. If the file doesn't exist, create it.
   */
  public function __construct(
    string $path,
    bool $create = false,
    int $mode = 0755,
  ) {
    $this->reset($path);

    if ($create) {
      $this->create($mode);
    }
  }

  /**
   * Return the last access time.
   */
  public function accessTime(): int {
    if ($this->exists()) {
      return fileatime($this->path());
    }

    return 0;
  }

  /**
   * Return the file name with extension.
   */
  public function basename(): string {
    return pathinfo($this->path(), PATHINFO_BASENAME);
  }

  /**
   * Return the last inode change time.
   */
  public function changeTime(): int {
    if ($this->exists()) {
      return filectime($this->path());
    }

    return 0;
  }

  /**
   * Change the group of the file.
   */
  public function chgrp(int $group, bool $_recursive = false): bool {
    if (!$this->exists()) {
      return false;
    }

    $path = $this->path();

    $this->reset();

    if (is_link($path)) {
      return lchgrp($path, $group);
    }

    return chgrp($path, $group);
  }

  /**
   * Change the permissions mode of the file.
   */
  public function chmod(int $mode, bool $_recursive = false): bool {
    if (!$this->exists()) {
      return false;
    }

    $this->reset();

    return chmod($this->path(), $mode);
  }

  /**
   * Change the owner of the file.
   */
  public function chown(int $user, bool $_recursive = false): bool {
    if (!$this->exists()) {
      return false;
    }

    $path = $this->path();

    $this->reset();

    if (is_link($path)) {
      return lchown($path, $user);
    }

    return chown($path, $user);
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
    string $target,
    int $process = self::OVERWRITE,
    int $mode = 0755,
  ): ?Node;

  /**
   * Create the node if it doesn't exist.
   */
  abstract public function create(int $mode = 0755): bool;

  /**
   * Remove the node if it exists.
   */
  abstract public function delete(): bool;

  /**
   * Helper method for deleting a file or folder.
   */
  public static function destroy(string $path): bool {
    if (!file_exists($path)) {
      return false;
    }

    return static::load($path)->delete();
  }

  /**
   * Return the parent directory as a string.
   * Will always end in a trailing slash.
   */
  public function dir(): string {
    return dirname($this->path()).'/';
  }

  /**
   * Is the file executable.
   */
  public function executable(): bool {
    return is_executable($this->path());
  }

  /**
   * Check if the file exists.
   */
  public function exists(): bool {
    return file_exists($this->path());
  }

  /**
   * Return the group name for the file.
   */
  public function group(): int {
    if ($this->exists()) {
      return filegroup($this->path());
    }

    return 0;
  }

  /**
   * Return true if the current path is absolute.
   */
  public function isAbsolute(): bool {
    return Path::isAbsolute($this->path());
  }

  /**
   * Return true if the current path is relative.
   */
  public function isRelative(): bool {
    return Path::isRelative($this->path());
  }

  /**
   * Attempt to load a file or folder object at a target location.
   */
  public static function load(string $path): Node {
    if (!file_exists($path)) {
      throw new MissingFileException(
        Str\format('No file or folder found at  %s', $path),
      );
    }

    if (is_dir($path)) {
      return new Folder($path);
    }

    return new File($path);
  }

  /**
   * Return the last modified time.
   */
  public function modifyTime(): int {
    if ($this->exists()) {
      return filemtime($this->path());
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
  public function move(string $target, bool $overwrite = true): bool {
    if (!$this->exists()) {
      return false;
    }

    // Don't move if the target exists and overwrite is disabled
    if (file_exists($target)) {
      if ($overwrite) {
        static::destroy($target);
      } else {
        throw new ExistingFileException(
          'Cannot move file as the target already exists',
        );
      }
    }

    // Move folders
    if (rename($this->path(), $target)) {
      $this->reset($target);

      return true;
    }

    return false;
  }

  /**
   * Return the file name without extension.
   */
  public function name(): string {
    return pathinfo($this->path(), PATHINFO_FILENAME);
  }

  /**
   * Return the owner name for the file.
   */
  public function owner(): int {
    if ($this->exists()) {
      return fileowner($this->path());
    }

    return 0;
  }

  /**
   * Alias for pwd().
   */
  public function path(): string {
    return $this->pwd();
  }

  /**
   * Return the parent folder as a Folder object.
   */
  public function parent(): ?Folder {
    if ($this->parent) {
      return $this->parent;
    }

    $folder = dirname($this->path());

    if ($folder !== '.' && $folder !== '/') {
      $this->parent = new Folder($folder);
    }

    return $this->parent;
  }

  /**
   * Return the permissions for the file.
   */
  public function permissions(): string {
    if ($this->exists()) {
      return Str\slice(Str\format('%o', fileperms($this->path())), -4);
    }

    return '';
  }

  /**
   * Return the current path (print working directory).
   */
  public function pwd(): string {
    return $this->path;
  }

  /**
   * Is the file readable.
   */
  public function readable(): bool {
    return is_readable($this->path());
  }

  /**
   * Rename the file within the current folder. If a file exists at the target path,
   * either delete the file if `$overwrite` is true, or throw an exception.
   *
   * Use `move()` to re-locate the file to another folder.
   *
   * @throws ExistingFileException
   */
  public function rename(string $name, bool $overwrite = true): bool {
    if (!$this->exists()) {
      return false;
    }

    // Remove unwanted characters
    $name = preg_replace(
      '/[^_\-\p{Ll}\p{Lm}\p{Lo}\p{Lt}\p{Lu}\p{Nd}]/imu',
      '-',
      basename($name),
    );

    // Return early if the same name
    if ($name === $this->name()) {
      return true;
    }

    // Prepend folder
    $target = $this->dir().$name;

    // Don't move if the target exists and overwrite is disabled
    if (file_exists($target)) {
      if ($overwrite) {
        static::destroy($target);
      } else {
        throw new ExistingFileException(
          'Cannot rename file as the target already exists',
        );
      }
    }

    // Rename the file within the current folder
    if (rename($this->path(), $target)) {
      $this->reset($target);

      return true;
    }

    return false;
  }

  /**
   * Reset the cache and path.
   */
  public function reset(string $path = ''): this {
    if ('' !== $path) {
      $this->path = $path;
    }

    clearstatcache();

    return $this;
  }

  /**
   * Return the current file size.
   */
  abstract public function size(): int;

  /**
   * Is the file writable.
   */
  public function writable(): bool {
    return is_writable($this->path());
  }

}
