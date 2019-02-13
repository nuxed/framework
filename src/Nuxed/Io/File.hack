namespace Nuxed\Io;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use type Nuxed\Io\Exception\ExistingFileException;
use type Nuxed\Io\Exception\InvalidPathException;
use function is_dir;
use function filesize;
use function file_exists;
use function pathinfo;
use function flock;
use function fopen;
use function fclose;
use function touch;
use function fread;
use function fread;
use function copy;
use function md5_file;
use function unlink;
use function finfo_close;
use function fwrite;
use function finfo_file;
use function finfo_open;
use function stream_set_blocking;
use function clearstatcache;
use function tempnam;
use function sys_get_temp_dir;
use const LOCK_EX;
use const LOCK_SH;
use const LOCK_UN;
use const LOCK_NB;
use const PATHINFO_EXTENSION;
use const FILEINFO_MIME_TYPE;
use const PATHINFO_BASENAME;
use const PATHINFO_FILENAME;

class File extends Node {

  /**
   * Resource handle.
   */
  protected ?resource $handle;

  /**
   * Current read / write mode.
   */
  protected string $mode = '';

  public static function temporary(
    string $perfix,
    ?string $directory = null,
  ): File {
    return new self(tempnam($directory ?? sys_get_temp_dir(), $perfix), true);
  }

  /**
   * Append data to the end of a file.
   */
  public function append(string $data): bool {
    return $this->write($data, 'ab', false);
  }

  /**
   * Close the current file resource handler.
   */
  public function close(): bool {
    if ($this->handle is resource) {
      $this->unlock();

      return fclose($this->handle as nonnull);
    }

    return false;
  }

  /**
   * {@inheritdoc}
   *
   * @throws \Nuxed\Io\Exception\ExistingFileException
   */
  <<__Override>>
  public function copy(
    string $target,
    int $process = self::OVERWRITE,
    int $mode = 0755,
  ): ?File {
    if (!$this->exists()) {
      return null;
    }

    if (file_exists($target) && $process !== self::OVERWRITE) {
      throw new ExistingFileException(
        'Cannot copy file as the target already exists',
      );
    }

    if (copy($this->path(), $target)) {
      $file = new File($target);
      $file->chmod($mode);

      return $file;
    }

    return null;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function create(int $mode = 0755): bool {
    $folder = $this->parent();

    if (!$folder) {
      return false;
    }

    if (!$folder->exists()) {
      $folder->create();
    }

    if (!$this->exists() && $folder->writable()) {
      if (touch($this->path())) {
        if ($mode) {
          $this->chmod($mode);
        }

        return true;
      }
    }

    return false;
  }

  /**
   * Remove the file if it exists.
   */
  <<__Override>>
  public function delete(): bool {
    if ($this->exists()) {
      $this->close();
      $this->reset();

      $ret = unlink($this->path());
      clearstatcache();
      return $ret;
    }

    return false;
  }

  /**
   * Return the file extension.
   */
  public function ext(): string {
    return Str\lowercase(pathinfo($this->path(), PATHINFO_EXTENSION));
  }

  /**
   * Lock a file for reading or writing.
   */
  public function lock(int $mode = LOCK_SH | LOCK_NB): bool {
    if ($this->handle is resource) {
      return flock($this->handle, $mode);
    }

    return false;
  }

  /**
   * Return an MD5 checksum of the file.
   */
  public function md5(bool $raw = false): string {
    if ($this->exists()) {
      return md5_file($this->path(), $raw);
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
   * Open a file resource handler for reading and writing.
   */
  public function open(string $mode): bool {
    if (!$this->exists()) {
      return false;
    }

    if ($this->handle is resource) {
      if ($mode === $this->mode) {
        return true;
      } else {
        $this->close();
      }
    }

    $this->reset();

    $this->handle = fopen($this->path(), $mode) ?: null;
    $this->mode = $mode;

    return
      ($this->handle is resource) && stream_set_blocking($this->handle, false);
  }

  /**
   * Prepend data to the beginning of a file.
   */
  public function prepend(string $data): bool {
    $content = $this->read();
    return $this->write($data.$content, 'wb', false);
  }

  /**
   * Open a file for reading. If $length is provided, will only read up to that limit.
   */
  public function read(int $length = -1, string $mode = 'rb'): string {
    if (!$this->open($mode)) {
      return '';
    }

    if ($this->lock()) {
      if ($length === -1) {
        $length = $this->size() ?: 1;
      }

      $content = fread($this->handle as nonnull, $length);

      $this->close();

      return $content;
    }

    return '';
  }

  public function lines(): Lines {
    return $this->read()
      |> Str\replace($$, "\r\n", "\n")
      |> Str\replace($$, "\r", "\n")
      |> Str\split($$, "\n")
      |> (C\last($$) === '' ? Vec\slice($$, 0, C\count($$) - 1) : $$)
      |> new Lines($$);
  }

  /**
   * Reset the cache and path.
   *
   * @throws InvalidPathException
   */
  <<__Override>>
  public function reset(string $path = ''): this {
    if ($path !== '' && file_exists($path) && is_dir($path)) {
      throw new InvalidPathException(
        Str\format('Invalid file path %s, folders are not allowed', $path),
      );
    }

    return parent::reset($path);
  }

  /**
   * Return the current file size.
   *
   * @return int
   */
  <<__Override>>
  public function size(): int {
    if ($this->exists()) {
      return filesize($this->path());
    }

    return 0;
  }

  /**
   * Unlock a file for reading or writing.
   */
  public function unlock(): bool {
    if ($this->handle is resource) {
      return flock($this->handle, LOCK_UN | LOCK_NB);
    }

    return false;
  }

  /**
   * Write data to a file (will erase any previous contents).
   */
  public function write(
    string $data,
    string $mode = 'wb',
    bool $close = true,
  ): bool {
    if (!$this->open($mode)) {
      return false;
    }

    if ($this->lock(LOCK_EX | LOCK_NB)) {
      $result = fwrite($this->handle as nonnull, $data);

      $this->unlock();

      if ($close) {
        $this->close();
      }

      return (bool)$result;
    }

    return false;
  }

}
