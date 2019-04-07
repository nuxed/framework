namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Event;
use namespace Nuxed\Container;
use type Nuxed\Contract\Event\EventDispatcherInterface;

class EventServiceProvider implements Container\ServiceProviderInterface {
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      EventDispatcherInterface::class,
      new Event\EventDispatcherFactory(),
      true,
    );
  }
}
