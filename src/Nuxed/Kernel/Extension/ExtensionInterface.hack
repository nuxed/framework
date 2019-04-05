namespace Nuxed\Kernel\Extension;

use type His\Container\ContainerInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;

interface ExtensionInterface {
  public function __construct(ContainerInterface $container);

  public function subscribe(EventDispatcherInterface $events): void;

  public function route(RouteCollectorInterface $router): void;

  public function pipe(MiddlewarePipeInterface $pipe): void;
}
