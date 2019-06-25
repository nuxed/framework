namespace Nuxed\Kernel\Extension;

use namespace Nuxed\{Container, EventDispatcher};
use namespace Nuxed\Http\{Router, Server};

abstract class AbstractExtension implements IExtension {
  public function register(Container\ContainerBuilder $_builder): void {}

  public function subscribe(
    EventDispatcher\IEventDispatcher $_events,
    Container\IServiceContainer $_container,
  ): void {}

  public function route(
    Router\IRouteCollector $_routes,
    Container\IServiceContainer $_container,
  ): void {}

  public function stack(
    Server\MiddlewareStack $_middleware,
    Container\IServiceContainer $_container,
  ): void {}
}
