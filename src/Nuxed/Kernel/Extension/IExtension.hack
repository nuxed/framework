namespace Nuxed\Kernel\Extension;

use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Container;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Router;

interface IExtension extends Container\IServiceProvider {
  public function subscribe(
    EventDispatcher\IEventDispatcher $events,
    Container\IServiceContainer $container,
  ): void;

  public function route(
    Router\IRouter $router,
    Container\IServiceContainer $container,
  ): void;

  public function stack(
    Server\MiddlewareStack $middleware,
    Container\IServiceContainer $container,
  ): void;
}
