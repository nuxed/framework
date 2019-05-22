namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;

class ImplicitOptionsMiddlewareFactory
  implements Container\IFactory<ImplicitOptionsMiddleware> {
  public function create(
    Container\IServiceContainer $_container,
  ): ImplicitOptionsMiddleware {
    return new ImplicitOptionsMiddleware();
  }
}
