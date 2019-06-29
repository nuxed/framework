namespace Nuxed\Http\Server\Exception;

use namespace HH\Lib\Str;
use namespace Nuxed\Http\Server;

final class EmptyStackException
  extends \OutOfBoundsException
  implements IException {
  public static function forClass(
    classname<Server\IRequestHandler> $class,
  ): this {
    return new static(Str\format(
      '%s cannot handle request; no middleware available to process the request.',
      $class,
    ));
  }
}
