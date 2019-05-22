namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Router;
use namespace Nuxed\Contract;

class RouteMiddlewareFactory implements Container\IFactory<RouteMiddleware> {
  public function create(
    Container\IServiceContainer $container,
  ): RouteMiddleware {
    return new RouteMiddleware($container->get(Router\Router::class));
  }
}
