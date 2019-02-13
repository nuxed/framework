namespace Nuxed\Log\Handler;

use namespace HH\Lib\Str;
use namespace Nuxed\Log\Exception;
use type Nuxed\Contract\Log\LogLevel;
use type Nuxed\Log\record;
use function fclose;
use function flock;
use function fwrite;
use function chmod;
use function fopen;
use function dirname;
use function is_dir;
use function set_error_handler;
use function restore_error_handler;
use function mkdir;
use function preg_replace;
use const LOCK_EX;
use const LOCK_UN;

class StreamHandler extends AbstractHandler {
  protected ?resource $stream;
  protected string $url;
  private ?string $errorMessage;
  protected ?int $filePermission;
  protected bool $useLocking;
  private bool $dirCreated;

  /**
   * @param LogLevel        $level          The minimum logging level at which this handler will be triggered
   * @param bool            $bubble         Whether the messages that are handled can bubble up the stack or not
   * @param int|null        $filePermission Optional file permissions (default (0644) are only for owner read/write)
   * @param bool            $useLocking     Try to lock log file before doing any writes
   */
  public function __construct(
    string $url,
    LogLevel $level = LogLevel::DEBUG,
    bool $bubble = true,
    ?int $filePermission = null,
    bool $useLocking = false,
  ) {
    parent::__construct($level, $bubble);
    $this->url = $url;
    $this->filePermission = $filePermission;
    $this->useLocking = $useLocking;
    $this->dirCreated = false;
  }

  <<__Override>>
  public function close(): void {
    if ($this->url !== '' && $this->stream is resource) {
      fclose($this->stream);
    }

    $this->stream = null;
  }

  /**
   * Return the currently active stream if it is open
   */
  public function getStream(): ?resource {
    return $this->stream;
  }

  /**
   * Return the stream URL if it was configured with a URL and not an active resource
   */
  public function getUrl(): ?string {
    return $this->url;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  protected function write(record $record): void {
    $message = $record['formatted'] ?? $record['message'];

    if (null === $this->stream) {
      if (null === $this->url || '' === $this->url) {
        throw new Exception\LogicException(
          'Missing stream url, the stream can not be opened. This may be caused by a premature call to close().',
        );
      }

      $this->createDir();
      $this->errorMessage = null;
      set_error_handler([$this, 'customErrorHandler']);
      $this->stream = fopen($this->url, 'a') ?: null;

      if ($this->filePermission !== null) {
        @chmod($this->url, $this->filePermission);
      }

      restore_error_handler();

      if (null === $this->stream) {
        throw new Exception\UnexpectedValueException(Str\format(
          'The stream or file "%s" could not be opened: %s',
          $this->url,
          $this->errorMessage ?? '',
        ));
      }
    }

    if ($this->useLocking) {
      flock($this->stream, LOCK_EX);
    }

    /* HH_IGNORE_ERROR[4110] */
    $this->streamWrite($this->stream, $message);

    if ($this->useLocking) {
      flock($this->stream as nonnull, LOCK_UN);
    }
  }

  /**
   * Write to stream
   */
  protected function streamWrite(resource $stream, string $message): void {
    fwrite($stream, $message);
  }

  protected function customErrorHandler(int $_, string $msg): void {
    $this->errorMessage = preg_replace('{^(fopen|mkdir)\(.*?\): }', '', $msg);
  }

  private function getDirFromStream(string $stream): ?string {
    $pos = Str\search($stream, '://');

    if (null === $pos) {
      return dirname($stream);
    }

    if ('file://' === Str\slice($stream, 0, 7)) {
      return dirname(Str\slice($stream, 7));
    }

    return null;
  }

  private function createDir(): void {
    // Do not try to create dir if it has already been tried.
    if ($this->dirCreated) {
      return;
    }

    $dir = $this->getDirFromStream($this->url);
    if (null !== $dir && !is_dir($dir)) {
      $this->errorMessage = null;
      set_error_handler([$this, 'customErrorHandler']);
      $status = mkdir($dir, 0777, true);
      restore_error_handler();
      if (false === $status && !is_dir($dir)) {
        throw new \UnexpectedValueException(Str\format(
          'There is no existing directory at "%s" and its not buildable: %s',
          $dir,
          $this->errorMessage ?? '',
        ));
      }
    }

    $this->dirCreated = true;
  }
}
