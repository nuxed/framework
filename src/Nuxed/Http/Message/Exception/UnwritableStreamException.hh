<?hh // strict

namespace Nuxed\Http\Message\Exception;

use type RuntimeException;

<<__ConsistentConstruct>>
class UnwritableStreamException
  extends RuntimeException
  implements ExceptionInterface {
  public static function dueToConfiguration(): this {
    return new static('Stream is not writable');
  }

  public static function dueToMissingResource(): this {
    return new static('No resource available; cannot write');
  }

  public static function dueToPhpError(): this {
    return new static('Error writing to stream');
  }
}
