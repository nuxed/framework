namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

class MethodNotAllowedMiddlewareFactory
  implements Container\IFactory<MethodNotAllowedMiddleware> {
  public function create(
    Container\IServiceContainer $_container,
  ): MethodNotAllowedMiddleware {
    return new MethodNotAllowedMiddleware();
  }
}
