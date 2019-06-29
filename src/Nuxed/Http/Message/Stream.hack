namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Str};

/**
 * Logic largely refactored from the Hsl Experimental HH\Lib\_Private\NativeHandler class.
 *
 * @see       https://github.com/hhvm/hsl-experimental/blob/master/src/io/_Private/NativeHandle.php
 * @copyright Copyright (c) 2004-present, Facebook, Inc. (https://www.facebook.com)
 * @license   https://github.com/hhvm/hsl-experimental/blob/master/LICENSE.md MIT License
 */

<<__ConsistentConstruct>>
class Stream implements IStream {
  private ?Awaitable<mixed> $lastOperation;
  private bool $isAwaitable = true;
  private ?int $size;

  public function __construct(private resource $impl) {
    /* HH_IGNORE_ERROR[2049] __PHPStdLib */
    /* HH_IGNORE_ERROR[4107] __PHPStdLib */
    \stream_set_blocking($impl, false);
  }

  protected function queuedAsync<T>(
    (function(): Awaitable<T>) $next,
  ): Awaitable<T> {
    $last = $this->lastOperation;
    $queue = async {
      await $last;
      return await $next();
    };
    $this->lastOperation = $queue;
    return $queue;
  }

  final public function rawReadBlocking(?int $max_bytes = null): string {
    if (!$this->isReadable()) {
      throw new Exception\UnreadableStreamException('Stream is unreadable.');
    }

    if ($max_bytes is int && $max_bytes < 0) {
      throw new Exception\InvalidArgumentException(
        'Expected $max_bytes to be null, or >= 0',
      );
    }

    if ($max_bytes === 0) {
      return '';
    }
    /* HH_IGNORE_ERROR[2049] __PHPStdLib */
    /* HH_IGNORE_ERROR[4107] __PHPStdLib */
    $result = \stream_get_contents($this->impl, $max_bytes ?? -1);
    if ($result === false) {
      throw new Exception\RuntimeException();
    }
    return $result as string;
  }

  private async function selectAsync(int $flags): Awaitable<void> {
    if (!$this->isAwaitable) {
      return;
    }
    if ($this->isEndOfFile()) {
      return;
    }
    try {
      /* HH_FIXME[2049] *not* PHP stdlib */
      /* HH_FIXME[4107] *not* PHP stdlib */
      await \stream_await($this->impl, $flags);
    } catch (\InvalidOperationException $_) {
      // e.g. real files on Linux when using epoll
      $this->isAwaitable = false;
    }
  }

  final public async function readAsync(
    ?int $max_bytes = null,
  ): Awaitable<string> {
    if (!$this->isReadable()) {
      throw new Exception\UnreadableStreamException('Stream is unreadable.');
    }

    if ($max_bytes is int && $max_bytes < 0) {
      throw new Exception\InvalidArgumentException(
        'Expected $max_bytes to be null, or >= 0',
      );
    }

    $data = '';
    while (($max_bytes is null || $max_bytes > 0) && !$this->isEndOfFile()) {
      $chunk = $this->rawReadBlocking($max_bytes);
      $data .= $chunk;
      if ($max_bytes is nonnull) {
        $max_bytes -= Str\length($chunk);
      }
      if ($max_bytes is null || $max_bytes > 0) {
        await $this->selectAsync(\STREAM_AWAIT_READ);
      }
    }
    return $data;
  }

  final public async function readLineAsync(
    ?int $max_bytes = null,
  ): Awaitable<string> {
    if (!$this->isReadable()) {
      throw new Exception\UnreadableStreamException('Stream is unreadable.');
    }

    if ($max_bytes is int && $max_bytes < 0) {
      throw new Exception\InvalidArgumentException(
        'Expected $max_bytes to be null, or >= 0',
      );
    }

    await $this->flushAsync();

    if ($max_bytes is null) {
      // The placeholder value for 'default' is not documented
      /* HH_IGNORE_ERROR[2049] __PHPStdLib */
      /* HH_IGNORE_ERROR[4107] __PHPStdLib */
      $impl = () ==> \fgets($this->impl);
    } else {
      // ... but if you specify a value, it returns 1 less.
      /* HH_IGNORE_ERROR[2049] __PHPStdLib */
      /* HH_IGNORE_ERROR[4107] __PHPStdLib */
      $impl = () ==> \fgets($this->impl, $max_bytes + 1);
    }
    $data = $impl();
    while ($data === false && !$this->isEndOfFile()) {
      await $this->selectAsync(\STREAM_AWAIT_READ);
      $data = $impl();
    }
    return $data === false ? '' : $data;
  }

  final public function rawWriteBlocking(string $bytes): int {
    if (!$this->isWritable()) {
      throw new Exception\UnwritableStreamException('Stream is unwritable.');
    }
    $this->size = null;

    /* HH_IGNORE_ERROR[2049] __PHPStdLib */
    /* HH_IGNORE_ERROR[4107] __PHPStdLib */
    $result = \fwrite($this->impl, $bytes);
    if ($result === false) {
      throw new Exception\RuntimeException();
    }

    return $result as int;
  }


  final public function writeAsync(string $bytes): Awaitable<void> {
    return $this->queuedAsync(async () ==> {
      $this->size = null;
      while (true) {
        $written = $this->rawWriteBlocking($bytes);
        $bytes = Str\slice($bytes, $written);
        if ($bytes === '') {
          break;
        }
        await $this->selectAsync(\STREAM_AWAIT_WRITE);
      }
    });
  }

  final public function flushAsync(): Awaitable<void> {
    return $this->queuedAsync(async () ==> {
      /* HH_IGNORE_ERROR[2049] */
      /* HH_IGNORE_ERROR[4107] */
      @\fflush($this->impl);
    });
  }

  final public function isEndOfFile(): bool {
    /* HH_IGNORE_ERROR[2049] __PHPStdLib */
    /* HH_IGNORE_ERROR[4107] __PHPStdLib */
    return \feof($this->impl);
  }

  final public async function closeAsync(): Awaitable<void> {
    await $this->flushAsync();
    /* HH_IGNORE_ERROR[2049] __PHPStdLib */
    /* HH_IGNORE_ERROR[4107] __PHPStdLib */
    @\fclose($this->impl);
  }

  /**
   * Returns whether or not the stream is writable.
   */
  public function isWritable(): bool {
    $meta = @\stream_get_meta_data($this->impl);
    $mode = $meta['mode'] ?? '';

    return (
      Str\contains($mode, 'x') ||
      Str\contains($mode, 'w') ||
      Str\contains($mode, 'c') ||
      Str\contains($mode, 'a') ||
      Str\contains($mode, '+')
    );
  }

  /**
   * Returns whether or not the stream is readable.
   */
  public function isReadable(): bool {
    $meta = @\stream_get_meta_data($this->impl);
    $mode = $meta['mode'] ?? '';

    return (Str\contains($mode, 'r') || Str\contains($mode, '+'));
  }

  /**
   * Returns whether or not the stream is seekable.
   */
  public function isSeekable(): bool {
    $meta = @\stream_get_meta_data($this->impl);
    return $meta['seekable'] ?? false;
  }

  public function seek(
    int $offset,
    StreamSeekWhence $whence = StreamSeekWhence::SET,
  ): void {
    if (!$this->isSeekable()) {
      throw new Exception\UnseekableStreamException('Stream is not seekable');
    }

    $retval = @\fseek($this->impl, $offset, $whence as int);

    if ($retval === -1) {
      throw new Exception\UnseekableStreamException(
        'Error seeking within stream',
      );
    }
  }

  public function rewind(): void {
    $this->seek(0);
  }

  public function getSize(): ?int {
    if ($this->size is nonnull) {
      return $this->size;
    }

    $stats = @\fstat($this->impl);

    if ($stats !== false && C\contains_key($stats, 'size')) {
      $this->size = (int)$stats['size'];
      return $this->size;
    }

    return null;
  }

  public function tell(): int {
    $result = @\ftell($this->impl);

    if (false === $result) {
      throw new Exception\UntellableStreamException(
        'Error occurred during tell operation',
      );
    }

    return $result;
  }
}
