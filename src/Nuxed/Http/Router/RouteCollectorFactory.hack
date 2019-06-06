namespace Nuxed\Http\Router;

use namespace Nuxed\Container;

final class RouteCollectorFactory
  implements Container\IFactory<IRouteCollector> {
  public function create(
    Container\IServiceContainer $_container,
  ): IRouteCollector {
    return new RouteCollector();
  }
}
