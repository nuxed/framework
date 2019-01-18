<?hh //

namespace Nuxed\Http\Message\Exception;

use type RuntimeException;

<<__ConsistentConstruct>>
class UnseekableStreamException
  extends RuntimeException
  implements ExceptionInterface {
  public static function dueToConfiguration(): this {
    return new static('Stream is not seekable');
  }

  public static function dueToMissingResource(): this {
    return new static('No resource available; cannot seek position');
  }

  public static function dueToPhpError(): this {
    return new static('Error seeking within stream');
  }
}
