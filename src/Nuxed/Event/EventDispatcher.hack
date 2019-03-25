namespace Nuxed\Event;

use namespace HH\Asio;
use type Nuxed\Contract\Event\EventSubscriberInterface;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\StoppableEventInterface;
use type Nuxed\Contract\Event\EventListener;
use type SplPriorityQueue;
use function get_class;

final class EventDispatcher implements EventDispatcherInterface {
  private dict<
    classname<EventInterface>,
    SplPriorityQueue<EventListener<EventInterface>>,
  > $listeners = dict[];

  private ?Awaitable<void> $lastOperation;

  /**
   * Register an event listener with the dispatcher.
   */
  public function on<TEvent as EventInterface>(
    classname<TEvent> $event,
    EventListener<TEvent> $listener,
    int $priority = 0,
  ): void {
    $listeners = $this->listeners[$event] ??
      new SplPriorityQueue<EventListener<EventInterface>>();
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

    $stopped = new _Private\Ref(false);
    await Asio\vm($listeners, ($listener) ==> {
      if ($stopped->value) {
        return async {
        };
      }

      $queue = $this->queue($event, $listener, $stopped);
      return $queue;
    });

    await $this->lastOperation;
    return $event;
  }

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<EventInterface> $event): void {
    unset($this->listeners[$event]);
  }

  private function queue<TEvent as EventInterface>(
    TEvent $event,
    (function(TEvent): Awaitable<void>) $next,
    _Private\Ref<bool> $stopped,
  ): Awaitable<void> {
    $last = $this->lastOperation;
    $queue = async {
      await $last;
      if ($event is StoppableEventInterface && $event->isPropagationStopped()) {
        $stopped->value = true;
        return;
      }

      return await $next($event);
    };
    $this->lastOperation = $queue;
    return $queue;
  }
}
