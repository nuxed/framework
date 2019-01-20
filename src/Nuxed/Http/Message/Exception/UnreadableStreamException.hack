namespace Nuxed\Http\Message\Exception;

use type RuntimeException;

<<__ConsistentConstruct>>
class UnreadableStreamException
  extends RuntimeException
  implements ExceptionInterface {
  public static function dueToConfiguration(): this {
    return new static('Stream is not readable');
  }

  public static function dueToMissingResource(): this {
    return new static('No resource available; cannot read');
  }

  public static function dueToPhpError(): this {
    return new static('Error reading stream');
  }
}
