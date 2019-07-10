namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace HH\Lib\{C, Str, Vec};
use namespace Nuxed\EventDispatcher;

class PrioritizedListenerProvider implements IPrioritizedListenerProvider {
  private dict<string, dict<
    classname<EventDispatcher\IEvent>,
    vec<EventDispatcher\IEventListener<EventDispatcher\IEvent>>,
  >> $listeners = dict[];

  public function listen<T as EventDispatcher\IEvent>(
    classname<T> $event,
    EventDispatcher\IEventListener<T> $listener,
    int $priority = 1,
  ): void {
    $priority = Str\format('%d.0', $priority);
    if (
      C\contains_key($this->listeners, $priority) &&
      C\contains_key($this->listeners[$priority], $event) &&
      C\contains($this->listeners[$priority][$event], $listener)
    ) {
      return;
    }

    $priorityListeners = $this->listeners[$priority] ?? dict[];
    $eventListeners = $priorityListeners[$event] ?? vec[];
    $eventListeners[] = $listener;
    $priorityListeners[$event] = $eventListeners;
    /* HH_FIXME[4110] */
    $this->listeners[$priority] = $priorityListeners;
  }

  public async function getListeners<reify T as EventDispatcher\IEvent>(
    T $event,
  ): AsyncIterator<EventDispatcher\IEventListener<T>> {
    $priorities = Vec\keys($this->listeners)
      |> Vec\sort($$, ($a, $b) ==> $a <=> $b);

    foreach ($priorities as $priority) {
      foreach ($this->listeners[$priority] as $eventName => $listeners) {
        if ($event instanceof $eventName) {
          foreach ($listeners as $listener) {
            /* HH_FIXME[4110] */
            yield $listener;
          }
        }
      }
    }
  }
}
