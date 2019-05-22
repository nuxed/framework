namespace Nuxed\EventDispatcher;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

class EventDispatcherFactory implements Container\IFactory<IEventDispatcher> {
  public function create(Container\IServiceContainer $_): IEventDispatcher {
    return new EventDispatcher();
  }
}
