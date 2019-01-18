<?hh // strict

namespace Nuxed\Mix\Extension;

use type Nuxed\Container\ServiceProvider\ServiceProviderInterface;
use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Router\RouteCollectorInterface;
use type Nuxed\Http\Server\MiddlewareFactory;
use type Nuxed\Mix\Configuration;

interface ExtensionInterface extends ContainerAwareInterface {
  public function services(
    Configuration $configuration,
  ): Container<ServiceProviderInterface>;

  public function subscribe(EventDispatcherInterface $events): void;

  public function route(
    RouteCollectorInterface $router,
    MiddlewareFactory $middlewares,
  ): void;

  public function pipe(
    MiddlewarePipeInterface $pipe,
    MiddlewareFactory $middlewares,
  ): void;
}
