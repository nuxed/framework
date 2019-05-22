namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

class ImplicitOptionsMiddlewareFactory
  implements Container\IFactory<ImplicitOptionsMiddleware> {
  public function create(
    Container\IServiceContainer $_container,
  ): ImplicitOptionsMiddleware {
    return new ImplicitOptionsMiddleware();
  }
}
