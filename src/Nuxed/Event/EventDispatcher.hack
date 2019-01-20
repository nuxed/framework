namespace Nuxed\Event;

use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\StoppableEventInterface;
use type Nuxed\Contract\Event\EventListener;

use type SplPriorityQueue;
use function get_class;

class EventDispatcher implements EventDispatcherInterface {
  private dict<classname<EventInterface>, SplPriorityQueue<EventListener>>
    $listeners = dict[];

  /**
   * Register an event listener with the dispatcher.
   */
  public function on(
    classname<EventInterface> $event,
    EventListener $listener,
    int $priority = 0,
  ): void {
    $listeners =
      $this->listeners[$event] ?? new SplPriorityQueue<EventListener>();
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
  public function dispatch<TEvent as EventInterface>(TEvent $event): TEvent {
    $name = get_class($event);
    $listeners = $this->listeners[$name] ?? vec[];

    foreach ($listeners as $listener) {
      $listener($event);
      if ($event is StoppableEventInterface && $event->isPropagationStopped()) {
        break;
      }
    }

    /* HH_IGNORE_ERROR[4110] */
    return $event;
  }

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<EventInterface> $event): void {
    unset($this->listeners[$event]);
  }

  public function reset(): void {
    $this->listeners = dict[];
  }
}
