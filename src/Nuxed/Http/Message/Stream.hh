<?hh // strict

namespace Nuxed\Http\Message;

use namespace HH\Lib\C;
use type Nuxed\Contract\Http\Message\StreamInterface;
use type Nuxed\Util\StringableTrait;
use function fclose;
use function fwrite;
use function fstat;
use function ftell;
use function fseek;
use function feof;
use function fread;
use function stream_get_contents;
use function stream_get_meta_data;
use function stream_set_blocking;
use function strstr;
use const SEEK_SET;

<<__ConsistentConstruct>>
class Stream implements StreamInterface {
  use StringableTrait;

  protected ?resource $stream;

  protected mixed $uri;

  protected ?int $size;

  public function __construct(resource $body) {
    stream_set_blocking($body, false);

    $this->stream = $body;
    $this->uri = $this->getMetadata('uri');
  }

  public function toString(): string {
    try {
      if ($this->isSeekable()) {
        $this->seek(0);
      }
      return $this->getContents();
    } catch (\Exception $e) {
      return '';
    }
  }

  public function close(): void {
    if ($this->stream is resource) {
      fclose($this->stream);
      $this->detach();
    }
  }

  public function detach(): ?resource {
    if (null === $this->stream) {
      return null;
    }

    $result = $this->stream;

    $this->stream = null;

    $this->size = $this->uri = null;

    return $result;
  }

  public function getSize(): ?int {
    if (null !== $this->size) {
      return $this->size;
    }

    if (null === $this->stream) {
      return null;
    }

    $stats = fstat($this->stream);

    if (C\contains_key($stats, 'size')) {
      $this->size = (int)$stats['size'];
      return $this->size;
    }

    return null;
  }

  public function tell(): int {
    if (null === $this->stream) {
      throw Exception\UntellableStreamException::dueToMissingResource();
    }

    $result = ftell($this->stream);

    if (false === $result) {
      throw Exception\UntellableStreamException::dueToPhpError();
    }

    return $result;
  }

  public function eof(): bool {
    return null === $this->stream || feof($this->stream);
  }

  public function isSeekable(): bool {
    if (null === $this->stream) {
      return false;
    }

    $meta = stream_get_meta_data($this->stream);
    return $meta['seekable'];
  }

  public function seek(int $offset, int $whence = SEEK_SET): void {
    if (null === $this->stream) {
      throw Exception\UnseekableStreamException::dueToMissingResource();
    }

    if (!$this->isSeekable()) {
      throw Exception\UnseekableStreamException::dueToConfiguration();
    }

    $retval = fseek($this->stream, $offset, $whence);

    if ($retval === -1) {
      throw Exception\UnseekableStreamException::dueToPhpError();
    }
  }

  public function rewind(): void {
    $this->seek(0);
  }

  public function isWritable(): bool {
    if (null === $this->stream) {
      return false;
    }

    $meta = stream_get_meta_data($this->stream);
    $mode = $meta['mode'];

    return (
      strstr($mode, 'x') ||
      strstr($mode, 'w') ||
      strstr($mode, 'c') ||
      strstr($mode, 'a') ||
      strstr($mode, '+')
    );
  }

  public function write(string $string): int {
    if (null === $this->stream) {
      throw Exception\UnwritableStreamException::dueToMissingResource();
    }

    if (!$this->isWritable()) {
      throw Exception\UnwritableStreamException::dueToConfiguration();
    }

    $this->size = null;

    $result = fwrite($this->stream, $string);

    if (false === $result) {
      throw Exception\UnwritableStreamException::dueToPhpError();
    }

    return $result;
  }

  public function isReadable(): bool {
    if (null === $this->stream) {
      return false;
    }

    $meta = stream_get_meta_data($this->stream);
    $mode = $meta['mode'];

    return (strstr($mode, 'r') || strstr($mode, '+'));
  }

  public function read(int $length): string {
    if (null === $this->stream) {
      throw Exception\UnreadableStreamException::dueToMissingResource();
    }

    if (!$this->isReadable()) {
      throw Exception\UnreadableStreamException::dueToConfiguration();
    }

    $result = fread($this->stream, $length);

    if (false === $result) {
      throw Exception\UnreadableStreamException::dueToPhpError();
    }

    return $result;
  }

  public function getContents(): string {
    if (null === $this->stream) {
      throw Exception\UnreadableStreamException::dueToMissingResource();
    }

    if (!$this->isReadable()) {
      throw Exception\UnreadableStreamException::dueToConfiguration();
    }

    $contents = stream_get_contents($this->stream);

    if (false === $contents) {
      throw Exception\UnreadableStreamException::dueToPhpError();
    }

    return $contents;
  }

  public function getMetadata(?string $key = null): mixed {
    if (null === $this->stream) {
      return null === $key ? null : [];
    }

    $meta = stream_get_meta_data($this->stream);

    if (null === $key) {
      return $meta;
    }

    return C\contains_key($meta, $key) ? $meta[$key] : null;
  }
}
