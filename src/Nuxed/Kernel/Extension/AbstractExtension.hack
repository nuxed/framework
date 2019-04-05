namespace Nuxed\Kernel\Extension;

use type His\Container\ContainerInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;

<<__ConsistentConstruct>>
abstract class AbstractExtension implements ExtensionInterface {
  public function __construct(protected ContainerInterface $container) {}

  public function subscribe(EventDispatcherInterface $_events): void {}

  public function route(RouteCollectorInterface $_router): void {}

  public function pipe(MiddlewarePipeInterface $_pipe): void {}
}
