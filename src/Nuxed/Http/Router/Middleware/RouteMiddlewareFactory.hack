namespace Nuxed\Http\Router\Middleware;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Router;

class RouteMiddlewareFactory
  implements Service\FactoryInterface<RouteMiddleware> {
  public function create(
    Container\ContainerInterface $container,
  ): RouteMiddleware {
    return new RouteMiddleware($container->get(Router\RouterInterface::class));
  }
}
