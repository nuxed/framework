namespace Nuxed\Http\Message;

use namespace HH\Lib\Experimental\IO;

/**
 * Describes a data stream.
 *
 * Typically, an instance will wrap a Hack stream; this interface provides
 * a wrapper around the most common operations.
 */
interface IStream extends IO\ReadHandle, IO\WriteHandle {
  /**
   * Seek to a position in the stream.
   */
  public function seek(
    int $offset,
    StreamSeekWhence $whence = StreamSeekWhence::SET,
  ): void;

  /**
   * Seek to the beginning of the stream.
   *
   * If the stream is not seekable, this method will raise an exception;
   * otherwise, it will perform a seek(0).
   */
  public function rewind(): void;

  /**
   * Returns the current position of the file read/write pointer
   *
   * @return int Position of the file pointer
   */
  public function tell(): int;

  /**
   * Returns whether or not the stream is writable.
   */
  public function isWritable(): bool;

  /**
   * Returns whether or not the stream is readable.
   */
  public function isReadable(): bool;

  /**
   * Returns whether or not the stream is seekable.
   */
  public function isSeekable(): bool;
}
