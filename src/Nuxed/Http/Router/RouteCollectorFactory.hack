namespace Nuxed\Http\Router;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Router;

class RouteCollectorFactory
  implements Service\FactoryInterface<Router\RouteCollectorInterface> {
  public function create(
    Container\ContainerInterface $container,
  ): RouteCollector {
    return new RouteCollector($container->get(Router\RouterInterface::class));
  }
}
