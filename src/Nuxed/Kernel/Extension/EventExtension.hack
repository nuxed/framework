namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Container;
use namespace Nuxed\EventDispatcher;

final class EventExtension extends AbstractExtension {
  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      EventDispatcher\IEventDispatcher::class,
      new EventDispatcher\EventDispatcherFactory(),
      true,
    );
  }
}
