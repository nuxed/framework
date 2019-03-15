namespace Nuxed\Io;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Experimental\Filesystem;
use type Nuxed\Io\Exception\ExistingFileException;
use type Nuxed\Io\Exception\InvalidPathException;
use type Exception;
use function filesize;
use function touch;
use function copy;
use function md5_file;
use function link;
use function unlink;
use function symlink;
use function finfo_close;
use function finfo_file;
use function finfo_open;
use function clearstatcache;
use function tempnam;
use function sys_get_temp_dir;
use const FILEINFO_MIME_TYPE;
use const PATHINFO_BASENAME;
use const PATHINFO_FILENAME;

final class File extends Node {
  <<__ReturnDisposable>>
  public function getReadHandle(): Filesystem\DisposableFileReadHandle {
    if (!$this->readable()) {
      throw new Exception\UnreadableFileException(
        Str\format('File (%s) is not readable.', $this->path()->toString()),
      );
    }

    try {
      return Filesystem\open_read_only($this->path()->toString());
    } catch (Exception $e) {
      throw new Exception\RuntimeException(
        Str\format(
          'Error while opening file (%s) for reading.',
          $this->path()->toString(),
        ),
        $e->getCode(),
        $e,
      );
    }
  }

  <<__ReturnDisposable>>
  public function getWriteHandle(
    Filesystem\FileWriteMode $mode = Filesystem\FileWriteMode::OPEN_OR_CREATE,
  ): Filesystem\DisposableFileWriteHandle {
    if ($mode === Filesystem\FileWriteMode::MUST_CREATE && $this->exists()) {
      throw new Exception\ExistingFileException(Str\format(
        'Cannot re-create file (%s) for writing.',
        $this->path()->toString(),
      ));
    }

    $creating = $mode === Filesystem\FileWriteMode::OPEN_OR_CREATE ||
      $mode === Filesystem\FileWriteMode::MUST_CREATE;
    if (!$creating && !$this->exists()) {
      throw new Exception\MissingFileException(
        Str\format('File (%s) doesn\'t exist.', $this->path()->toString()),
      );
    }

    if (
      (
        !$creating ||
        ($mode === Filesystem\FileWriteMode::OPEN_OR_CREATE && $this->exists())
      ) &&
      !$this->writable()
    ) {
      throw new Exception\UnwritableFileException(
        Str\format('File (%s) is not writable.', $this->path()->toString()),
      );
    }

    try {
      return Filesystem\open_write_only($this->path()->toString(), $mode);
    } catch (Exception $e) {
      throw new Exception\RuntimeException(
        Str\format(
          'Error while opening file (%s) for writing (mode:%s).',
          $this->path()->toString(),
          $mode as string,
        ),
        $e->getCode(),
        $e,
      );
    }
  }

  public static async function temporary(
    string $perfix,
    Path $directory = Path::create(sys_get_temp_dir()),
  ): Awaitable<File> {
    $folder = new Folder($directory, true);
    if (!$folder->exists()) {
      await $folder->create();
    }
    return
      new self(Path::create(tempnam($directory->toString(), $perfix)), true);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function create(int $mode = 0755): Awaitable<bool> {
    $folder = $this->parent();

    if (null === $folder) {
      return false;
    }

    if (!$folder->exists()) {
      await $folder->create();
    }

    if (!$this->exists() && $folder->writable()) {
      if (touch($this->path()->toString())) {
        $ret = true;
        if ($mode) {
          $ret = await $this->chmod($mode);
        }

        return $ret;
      }
    }

    return false;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function copy(
    Path $target,
    OperationType $process = OperationType::OVERWRITE,
    int $mode = 0755,
  ): Awaitable<?File> {
    if (!$this->exists()) {
      return null;
    }

    if ($target->exists() && $process !== OperationType::OVERWRITE) {
      throw new ExistingFileException(
        'Cannot copy file as the target already exists.',
      );
    }

    if (copy($this->path()->toString(), $target->toString())) {
      $file = new File($target);
      await $file->chmod($mode);

      return $file;
    }

    return null;
  }

  /**
   * Remove the file if it exists.
   */
  <<__Override>>
  public async function delete(): Awaitable<bool> {
    if ($this->exists()) {
      $this->reset();

      $ret = unlink($this->path()->toString());
      clearstatcache();
      return $ret;
    }

    return false;
  }

  /**
   * Return the file extension.
   */
  public function extension(): ?string {
    return $this->path()->extension();
  }

  /**
   * Return an MD5 checksum of the file.
   */
  public function md5(bool $raw = false): string {
    if ($this->exists()) {
      return md5_file($this->path()->toString(), $raw);
    }

    return '';
  }

  /**
   * Return the mime type for the file.
   */
  public function mimeType(): string {
    if (!$this->exists()) {
      return '';
    }

    $info = finfo_open(FILEINFO_MIME_TYPE);
    $type = finfo_file($info, $this->path());
    finfo_close($info);

    return $type;
  }

  /**
   * Reset the cache and path.
   */
  <<__Override>>
  public function reset(Path $path = $this->path()): this {
    if ($path->exists() && $path->isDirectory()) {
      throw new InvalidPathException(
        Str\format(
          'Invalid file path (%s), folders are not allowed.',
          $path->toString(),
        ),
      );
    }

    return parent::reset($path);
  }

  /**
   * Append data to the end of a file.
   */
  public async function append(string $data): Awaitable<void> {
    try {
      await $this->write($data, Filesystem\FileWriteMode::APPEND);
    } catch (Exception $e) {
      throw new Exception\WriteErrorException(
        Str\format(
          'Error while appending data to file (%s).',
          $this->path()->toString(),
        ),
        $e->getCode(),
        $e,
      );
    }
  }

  /**
   * Prepend data to the beginning of a file.
   */
  public async function prepend(string $data): Awaitable<void> {
    try {
      $content = await $this->read();
      await $this->write($data.$content);
    } catch (Exception $e) {
      throw new Exception\WriteErrorException(
        Str\format(
          'Error while prepending data to file (%s).',
          $this->path()->toString(),
        ),
        $e->getCode(),
        $e,
      );
    }
  }

  /**
   * Write data to a file (will erase any previous contents).
   */
  public async function write(
    string $data,
    Filesystem\FileWriteMode $mode = Filesystem\FileWriteMode::TRUNCATE,
  ): Awaitable<void> {
    try {
      await using ($file = $this->getWriteHandle($mode)) {
        using (
          $lock = $file->lock(Filesystem\FileLockType::EXCLUSIVE_NON_BLOCKING)
        ) {
          await $file->writeAsync($data);
        }
      }
    } catch (Exception $e) {
      throw new Exception\WriteErrorException(
        Str\format(
          'Error while writing to file (%s).',
          $this->path()->toString(),
        ),
        $e->getCode(),
        $e,
      );
    }
  }

  /**
   * Open a file for reading. If $length is provided, will only read up to that limit.
   */
  public async function read(?int $length = null): Awaitable<string> {
    try {
      await using ($handle = $this->getReadHandle()) {
        using (
          $lock = $handle->lock(Filesystem\FileLockType::SHARED_NON_BLOCKING)
        ) {
          return await $handle->readAsync($length);
        }
      }
    } catch (Exception $e) {
      throw new Exception\ReadErrorException(
        Str\format(
          'Error while reading from file (%s).',
          $this->path()->toString(),
        ),
        $e->getCode(),
        $e,
      );
    }
  }

  public async function lines(): Awaitable<Lines> {
    $content = await $this->read();

    return $content
      |> Str\replace($$, "\r\n", "\n")
      |> Str\replace($$, "\r", "\n")
      |> Str\split($$, "\n")
      |> (C\last($$) === '' ? Vec\slice($$, 0, C\count($$) - 1) : $$)
      |> new Lines($$);
  }

  /**
   * Return the current file size.
   */
  <<__Override>>
  public async function size(): Awaitable<int> {
    if ($this->exists()) {
      return filesize($this->path()->toString());
    }

    return 0;
  }

  /**
   * Creates a symbolic link.
   */
  public async function symlink(Path $target): Awaitable<File> {
    if (!$this->exists()) {
      throw new Exception\MissingFileException(
        Str\format('File (%s) doesn\'t exist.', $this->path()->toString()),
      );
    }

    if ($target->exists()) {
      throw new Exception\InvalidPathException(
        Str\format('Target (%s) already exists.', $target->toString()),
      );
    }

    @symlink($this->path()->toString(), $target->toString());
    if (!$target->exists() || !$target->isSymlink()) {
      throw new Exception\RuntimeException(Str\format(
        'Error while creating a symbolic link (%s) for file (%s).',
        $target->toString(),
        $this->path()->toString(),
      ));
    }

    return new File($target);
  }

  /**
   * Create a hard link.
   */
  public async function link(Path $link): Awaitable<File> {
    if (!$this->exists()) {
      throw new Exception\MissingFileException(
        Str\format('File (%s) doesn\'t exist.', $this->path()->toString()),
      );
    }

    if ($link->exists()) {
      throw new Exception\InvalidPathException(
        Str\format('Link (%s) already exists.', $link->toString()),
      );
    }

    @link($this->path()->toString(), $link->toString());
    if (!$link->exists()) {
      throw new Exception\RuntimeException(Str\format(
        'Error while creating a hard link (%s) for file (%s).',
        $link->toString(),
        $this->path()->toString(),
      ));
    }

    return new File($link);
  }
}
