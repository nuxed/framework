namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace Nuxed\EventDispatcher;

interface IPrioritizedListenerProvider extends IAttachableListenerProvider {
  public function listen<T as EventDispatcher\IEvent>(
    classname<T> $event, EventDispatcher\IEventListener<T> $listener, int $priority = 1
  ): void;
}
