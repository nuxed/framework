<?hh // strict

namespace Nuxed\Kernel\Extension;

use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;
use type Nuxed\Container\ContainerAwareTrait;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Http\Server\MiddlewareFactory;
use type Nuxed\Kernel\Configuration;

abstract class AbstractExtension implements ExtensionInterface {
  use ContainerAwareTrait;

  public function services(
    Configuration $_configuration,
  ): Container<ServiceProviderInterface> {
    return vec[];
  }

  public function subscribe(EventDispatcherInterface $_events): void {}

  public function route(
    RouteCollectorInterface $_router,
    MiddlewareFactory $_middlewares,
  ): void {}

  public function pipe(
    MiddlewarePipeInterface $_pipe,
    MiddlewareFactory $_middlewares,
  ): void {}
}
