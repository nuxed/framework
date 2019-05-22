namespace Nuxed\Http\Server\Exception;

use namespace HH\Lib\Str;
use namespace Nuxed\Http\Server;

final class InvalidMiddlewareException
  extends \InvalidArgumentException
  implements IException {
  public static function forMiddleware(mixed $middleware): this {
    return new static(Str\format(
      'Middleware "%s" is neither a string service name, a "%s" instance, or a "%s" instance.',
      \is_object($middleware) ? \get_class($middleware) : \gettype($middleware),
      Server\IMiddleware::class,
      Server\IRequestHandler::class,
    ));
  }
}
