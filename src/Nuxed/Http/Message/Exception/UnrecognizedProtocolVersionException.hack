namespace Nuxed\Http\Message\Exception;

use namespace HH\Lib\Str;
use type UnexpectedValueException;

<<__ConsistentConstruct>>
class UnrecognizedProtocolVersionException
  extends UnexpectedValueException
  implements ExceptionInterface {
  public static function forVersion(string $version): this {
    return
      new static(Str\format('Unrecognized protocol version (%s)', $version));
  }
}
