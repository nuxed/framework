namespace Nuxed\EventDispatcher;

use namespace Nuxed\Container;

class EventDispatcherFactory implements Container\IFactory<IEventDispatcher> {
  public function create(Container\IServiceContainer $_): IEventDispatcher {
    return new EventDispatcher();
  }
}
