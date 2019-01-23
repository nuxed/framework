namespace Nuxed\Http\Message;

use function stream_get_contents;

class CachingStream extends Stream {
  private string $cache = '';

  private bool $reachedEof = false;

  <<__Override>>
  public function toString(): string {
    if ($this->reachedEof) {
      return $this->cache;
    }

    $this->getContents();
    return $this->cache;
  }

  <<__Override>>
  public function isWritable(): bool {
    return false;
  }

  <<__Override>>
  public function read(int $length): string {
    $content = parent::read($length);
    if (!$this->reachedEof) {
      $this->cache .= $content;
    }

    if ($this->eof()) {
      $this->reachedEof = true;
    }

    return $content;
  }

  <<__Override>>
  public function getContents(int $maxLength = -1): string {
    if ($this->reachedEof) {
      return $this->cache;
    }

    if (null === $this->stream) {
      throw Exception\UnreadableStreamException::dueToMissingResource();
    }

    if (!$this->isReadable()) {
      throw Exception\UnreadableStreamException::dueToConfiguration();
    }

    $contents = stream_get_contents($this->stream, $maxLength);

    if (false === $contents) {
      throw Exception\UnreadableStreamException::dueToPhpError();
    }

    $this->cache .= $contents;

    if ($maxLength === -1 || $this->eof()) {
      $this->reachedEof = true;
    }

    return $contents;
  }
}
