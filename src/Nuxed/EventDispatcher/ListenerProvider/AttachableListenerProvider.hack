namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace HH\Lib\C;
use namespace Nuxed\EventDispatcher;

class AttachableListenerProvider implements IAttachableListenerProvider {
  private dict<
    classname<EventDispatcher\IEvent>,
    vec<EventDispatcher\IEventListener<EventDispatcher\IEvent>>,
  > $listeners = dict[];

  public function listen<T as EventDispatcher\IEvent>(
    classname<T> $event,
    EventDispatcher\IEventListener<T> $listener,
  ): void {
    $listeners = $this->listeners[$event] ?? vec[];
    if (C\contains($listeners, $listener)) {
      // duplicate detected
      return;
    }

    $listeners[] = $listener;
    /* HH_FIXME[4110] */
    $this->listeners[$event] = $listeners;
  }

  public async function getListeners<
    reify T as EventDispatcher\IEvent,
  >(T $event): AsyncIterator<EventDispatcher\IEventListener<T>> {
    foreach ($this->listeners as $type => $listeners) {
      if ($event instanceof $type) {
        foreach ($listeners as $listener) {
          /* HH_FIXME[4110] */
          yield $listener;
        }
      }
    }
  }
}
