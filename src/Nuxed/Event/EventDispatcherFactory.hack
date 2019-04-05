namespace Nuxed\Event;

use namespace His\Container;
use namespace Nuxed\Contract\Event;
use namespace Nuxed\Contract\Service;

class EventDispatcherFactory
  implements Service\FactoryInterface<Event\EventDispatcherInterface> {
  public function create(
    Container\ContainerInterface $_,
  ): Event\EventDispatcherInterface {
    return new EventDispatcher();
  }
}
