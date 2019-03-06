namespace Nuxed\Io;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Experimental\Filesystem;
use type Nuxed\Io\Exception\ExistingFileException;
use type Nuxed\Io\Exception\InvalidPathException;
use function filesize;
use function pathinfo;
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
use const PATHINFO_EXTENSION;
use const FILEINFO_MIME_TYPE;
use const PATHINFO_BASENAME;
use const PATHINFO_FILENAME;

final class File extends Node {
  <<__ReturnDisposable>>
  public function getReadHandle(): Filesystem\DisposableFileReadHandle {
    return Filesystem\open_read_only($this->path()->toString());
  }

  <<__ReturnDisposable>>
  public function getWriteHandle(
    Filesystem\FileWriteMode $mode = Filesystem\FileWriteMode::OPEN_OR_CREATE,
  ): Filesystem\DisposableFileWriteHandle {
    return Filesystem\open_write_only($this->path()->toString(), $mode);
  }

  public static function temporary(
    string $perfix,
    Path $directory = Path::create(sys_get_temp_dir()),
  ): File {
    return new self(tempnam($directory->toString(), $perfix), true);
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public async function create(int $mode = 0755): Awaitable<bool> {
    $folder = $this->parent();

    if (!$folder) {
      return false;
    }

    if (!$folder->exists()) {
      await $folder->create();
    }

    if (!$this->exists() && $folder->writable()) {
      if (touch($this->path()->toString())) {
        if ($mode) {
          await $this->chmod($mode);
        }

        return true;
      }
    }

    return false;
  }

  /**
   * {@inheritdoc}
   *
   * @throws \Nuxed\Io\Exception\ExistingFileException
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
        'Cannot copy file as the target already exists',
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
  public function ext(): string {
    return
      Str\lowercase(pathinfo($this->path()->toString(), PATHINFO_EXTENSION));
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
   *
   * @throws InvalidPathException
   */
  <<__Override>>
  public function reset(Path $path = Path::create('')): this {
    if ($path->toString() !== '' && $path->exists() && $path->isDirectory()) {
      throw new InvalidPathException(
        Str\format(
          'Invalid file path %s, folders are not allowed',
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
    await $this->write($data, Filesystem\FileWriteMode::APPEND);
  }

  /**
   * Prepend data to the beginning of a file.
   */
  public async function prepend(string $data): Awaitable<void> {
    $content = await $this->read();
    await $this->write($data.$content);
  }

  /**
   * Write data to a file (will erase any previous contents).
   */
  public async function write(
    string $data,
    Filesystem\FileWriteMode $mode = Filesystem\FileWriteMode::TRUNCATE,
  ): Awaitable<void> {
    await using ($file = $this->getWriteHandle($mode)) {
      using (
        $lock = $file->lock(Filesystem\FileLockType::EXCLUSIVE_NON_BLOCKING)
      ) {
        await $file->writeAsync($data);
      }
    }
  }

  /**
   * Open a file for reading. If $length is provided, will only read up to that limit.
   */
  public async function read(int $length = -1): Awaitable<string> {
    await using ($handle = $this->getReadHandle()) {
      using (
        $lock = $handle->lock(Filesystem\FileLockType::SHARED_NON_BLOCKING)
      ) {
        return await $handle->readAsync($length);
      }
    }
  }

  public async function lines(): Awaitable<Lines> {
    return $this->read()
      |> Asio\join($$)
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
  public function symlink(Path $link): void {
    if ($link->exists()) {
      throw new Exception\InvalidArgumentException('Target already exists.');
    }

    symlink($this->path()->toString(), $link->toString());
  }

  /**
   * Create a hard link.
   */
  public function link(Path $link): void {
    if ($link->exists()) {
      throw new Exception\InvalidArgumentException('Link already exists.');
    }

    link($this->path()->toString(), $link->toString());
  }
}
