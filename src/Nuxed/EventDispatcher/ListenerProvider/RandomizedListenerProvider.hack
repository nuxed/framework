namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace HH\Lib\{C, Vec};
use namespace Nuxed\EventDispatcher;

class RandomizedListenerProvider implements IRandomizedListenerProvider {
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

  public async function getListeners<reify T as EventDispatcher\IEvent>(
    T $event,
  ): AsyncIterator<EventDispatcher\IEventListener<T>> {
    $listeners = vec[];
    foreach ($this->listeners as $type => $eventListeners) {
      if (\is_a($event, $type)) {
        $listeners = Vec\concat($listeners, $eventListeners);
      }
    }

    foreach (Vec\shuffle($listeners) as $listener) {
      /* HH_FIXME[4110] */
      yield $listener;
    }
  }
}
