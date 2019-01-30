namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Event;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Container\Container;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class EventServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    EventDispatcherInterface::class,
  ];

  <<__Override>>
  public function register(Container $container): void {
    $container->share(
      EventDispatcherInterface::class,
      Event\EventDispatcher::class,
    );
  }
}
