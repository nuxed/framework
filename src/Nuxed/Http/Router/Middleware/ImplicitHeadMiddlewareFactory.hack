namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Router;

class ImplicitHeadMiddlewareFactory
  implements Container\IFactory<ImplicitHeadMiddleware> {
  public function create(
    Container\IServiceContainer $container,
  ): ImplicitHeadMiddleware {
    return new ImplicitHeadMiddleware($container->get(Router\Router::class));
  }
}
