namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace HH\Lib\C;
use namespace HH\ReifiedGenerics;
use namespace Nuxed\EventDispatcher;

class ReifiedListenerProvider implements IReifiedListenerProvider {
  private dict<
    classname<EventDispatcher\IEvent>,
    vec<EventDispatcher\IEventListener<EventDispatcher\IEvent>>,
  > $listeners = dict[];

  public function listen<<<__Enforceable>> reify T as EventDispatcher\IEvent>(
    EventDispatcher\IEventListener<T> $listener,
  ): void {
    /* HH_FIXME[2049] */
    /* HH_FIXME[4107] */
    $event = ReifiedGenerics\getClassname<T>();

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
    foreach ($this->listeners as $type => $listeners) {
      if (\is_a($event, $type)) {
        foreach ($listeners as $listener) {
          /* HH_FIXME[4110] */
          yield $listener;
        }
      }
    }
  }
}
