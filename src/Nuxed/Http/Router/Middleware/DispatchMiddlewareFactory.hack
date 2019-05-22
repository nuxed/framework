namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

class DispatchMiddlewareFactory
  implements Container\IFactory<DispatchMiddleware> {
  public function create(
    Container\IServiceContainer $_container,
  ): DispatchMiddleware {
    return new DispatchMiddleware();
  }
}
