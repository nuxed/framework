namespace Nuxed\Io;

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

class Folder extends Node {

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
  public function chgrp(int $group, bool $recursive = false): bool {
    if ($recursive) {
      if ($contents = $this->read()) {
        foreach ($contents as $file) {
          $file->chgrp($group, true);
        }
      }
    }

    return parent::chgrp($group);
  }

  /**
   * Change the permissions mode of the file.
   * If $recursive is true, set the mode on all children.
   */
  <<__Override>>
  public function chmod(int $mode, bool $recursive = false): bool {
    if ($recursive) {
      if ($contents = $this->read()) {
        foreach ($contents as $file) {
          $file->chmod($mode, true);
        }
      }
    }

    return parent::chmod($mode);
  }

  /**
   * Change the owner of the file.
   * If $recursive is true, set the owner on all children.
   */
  <<__Override>>
  public function chown(int $user, bool $recursive = false): bool {
    if ($recursive) {
      if ($contents = $this->read()) {
        foreach ($contents as $file) {
          $file->chown($user, true);
        }
      }
    }

    return parent::chown($user);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function create(int $mode = 0755): bool {
    $ret = false;
    if (!$this->exists()) {
      $ret = (bool)@mkdir($this->path(), $mode, true);
    }
    $this->reset();

    return $ret;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function copy(
    string $target,
    int $process = self::MERGE,
    int $mode = 0755,
  ): ?Node {
    if (!$this->exists()) {
      return null;
    }

    // Delete the target folder if overwrite is true
    if ($process === self::OVERWRITE && file_exists($target)) {
      static::destroy($target);
    }

    // Create the target folder and reset folder path
    $destination = new Folder($target, true, $mode);
    $target = $destination->path();

    // Recursively copy over contents to new destination
    if ($contents = $this->read()) {
      foreach ($contents as $file) {
        $to = Str\replace($file->path(), $this->path(), $target);

        // Skip copy if target exists
        if ($process === self::SKIP && file_exists($to)) {
          continue;
        }

        // Delete target since File::copy() will throw exception
        if ($process === self::MERGE && file_exists($to) && is_file($to)) {
          @unlink($to);
        }

        $file->copy($to, $process, $mode);
      }
    }

    clearstatcache();

    return $destination;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function delete(): bool {
    if (!$this->exists()) {
      return false;
    }

    $this->flush()->reset();

    return rmdir($this->path());
  }

  /**
   * Recursively delete all files and folders within this folder.
   */
  public function flush(): this {
    foreach ($this->read(false, true) as $file) {
      $file->delete();
    }

    return $this;
  }

  /**
   * Scan the folder and return a list of File objects.
   */
  public function files(
    bool $sort = false,
    bool $recursive = false,
  ): Container<File> {
    /* HH_IGNORE_ERROR[4110] `read()` returns `Container<Node>` while we need `Container<File>` */
    return $this->read($sort, $recursive, self::FILES);
  }

  /**
   * Find all files and folders within the current folder that match a specific pattern.
   */
  public function find(
    string $pattern,
    int $filter = self::ALL,
  ): Container<Node> {
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

    /** @var \SPLFileInfo $file */
    foreach ($iterator as $file) {
      if (
        $file->isDir() && ($filter === self::ALL || $filter === self::FOLDERS)
      ) {
        $contents[] = new Folder($file->getPathname());

      } else if (
        $file->isFile() && ($filter === self::ALL || $filter === self::FILES)
      ) {
        $contents[] = new File($file->getPathname());
      }
    }

    return $contents;
  }

  /**
   * Scan the folder and return a list of Folder objects.
   */
  public function folders(
    bool $sort = false,
    bool $recursive = false,
  ): Container<Folder> {
    /* HH_IGNORE_ERROR[4110] `read()` returns `Container<Node>` while we need `Container<Folder>` */
    return $this->read($sort, $recursive, self::FOLDERS);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function move(string $target, bool $overwrite = true): bool {
    if (Path::normalize($target) === Path::normalize($this->path())) {
      return true; // Don't move to the same location
    }

    return parent::move($target, $overwrite);
  }

  /**
   * Scan the folder and return a list of File and Folder objects.
   */
  public function read(
    bool $sort = false,
    bool $recursive = false,
    int $filter = self::ALL,
  ): Container<Node> {
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
        $file->isDir() && ($filter === self::ALL || $filter === self::FOLDERS)
      ) {
        $contents[] = new Folder($file->getPathname());

      } else if (
        $file->isFile() && ($filter === self::ALL || $filter === self::FILES)
      ) {
        $contents[] = new File($file->getPathname());
      }
    }

    if ($sort) {
      $contents = Vec\sort(
        $contents,
        (Node $a, Node $b) ==> Str\compare($a->path(), $b->path()),
      );
    }

    return $contents;
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
  public function size(): int {
    if ($this->exists()) {
      return C\count($this->read());
    }

    return 0;
  }

}
