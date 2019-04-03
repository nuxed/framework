namespace Nuxed\Kernel\Extension;

use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;

interface ExtensionInterface extends ContainerAwareInterface {
  public function subscribe(EventDispatcherInterface $events): void;

  public function route(RouteCollectorInterface $router): void;

  public function pipe(MiddlewarePipeInterface $pipe): void;
}
