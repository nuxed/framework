namespace Nuxed\Event;

use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\StoppableEventInterface;
use type SplPriorityQueue;
use function get_class;

final class EventDispatcher implements EventDispatcherInterface {
  private dict<
    classname<EventInterface>,
    SplPriorityQueue<(function(EventInterface): Awaitable<void>)>,
  > $listeners = dict[];

  /**
   * Register an event listener with the dispatcher.
   */
  public function on<TEvent as EventInterface>(
    classname<TEvent> $event,
    (function(TEvent): Awaitable<void>) $listener,
    int $priority = 0,
  ): void {
    $listeners = $this->listeners[$event] ??
      new SplPriorityQueue<(function(EventInterface): Awaitable<void>)>();
    $listeners->insert($listener, $priority);
    $this->listeners[$event] = $listeners;
  }

  /**
   * Register an event subscriber with the dispatcher.
   */
  public function subscribe(EventSubscriberInterface $subscriber): void {
    $subscriber->subscribe($this);
  }

  /**
   * Dispatch an event and call the listeners.
   */
  public async function dispatch<TEvent as EventInterface>(
    TEvent $event,
  ): Awaitable<TEvent> {
    if ($event is StoppableEventInterface && $event->isPropagationStopped()) {
      // event is already stopped.
      return $event;
    }

    $name = get_class($event);
    $listeners = $this->listeners[$name] ?? vec[];
    $stopped = false;
    $lastOperation = async {
    };

    foreach ($listeners as $listener) {
      if ($stopped) {
        break;
      }

      $lastOperation = async {
        await $lastOperation;
        if (
          $event is StoppableEventInterface && $event->isPropagationStopped()
        ) {
          $stopped = true;
          return;
        }

        return await $listener($event);
      };
    }

    await $lastOperation;
    return $event;
  }

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<EventInterface> $event): void {
    unset($this->listeners[$event]);
  }
}
