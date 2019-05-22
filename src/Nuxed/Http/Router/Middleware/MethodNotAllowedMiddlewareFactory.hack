namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;

class MethodNotAllowedMiddlewareFactory
  implements Container\IFactory<MethodNotAllowedMiddleware> {
  public function create(
    Container\IServiceContainer $_container,
  ): MethodNotAllowedMiddleware {
    return new MethodNotAllowedMiddleware();
  }
}
