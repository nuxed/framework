namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace Nuxed\EventDispatcher;

interface IAttachableListenerProvider extends IListenerProvider {
  public function listen<T as EventDispatcher\IEvent>(
    classname<T> $event, EventDispatcher\IEventListener<T> $listener
  ): void;
}
