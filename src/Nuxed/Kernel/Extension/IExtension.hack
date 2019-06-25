namespace Nuxed\Kernel\Extension;

use namespace Nuxed\{Container, EventDispatcher};
use namespace Nuxed\Http\{Router, Server};

interface IExtension extends Container\IServiceProvider {
  public function subscribe(
    EventDispatcher\IEventDispatcher $events,
    Container\IServiceContainer $container,
  ): void;

  public function route(
    Router\IRouteCollector $routes,
    Container\IServiceContainer $container,
  ): void;

  public function stack(
    Server\MiddlewareStack $middleware,
    Container\IServiceContainer $container,
  ): void;
}
