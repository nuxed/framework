namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;

class DispatchMiddlewareFactory
  implements Container\IFactory<DispatchMiddleware> {
  public function create(
    Container\IServiceContainer $_container,
  ): DispatchMiddleware {
    return new DispatchMiddleware();
  }
}
