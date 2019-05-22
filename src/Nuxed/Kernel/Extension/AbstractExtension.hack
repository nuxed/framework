namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Router;
use namespace Nuxed\EventDispatcher;

abstract class AbstractExtension implements IExtension {
  public function register(Container\ContainerBuilder $_builder): void {}

  public function subscribe(
    EventDispatcher\IEventDispatcher $_events,
    Container\IServiceContainer $_container,
  ): void {}

  public function route(
    Router\IRouter $_router,
    Container\IServiceContainer $_container,
  ): void {}

  public function stack(
    Server\MiddlewareStack $_middleware,
    Container\IServiceContainer $_container,
  ): void {}
}
