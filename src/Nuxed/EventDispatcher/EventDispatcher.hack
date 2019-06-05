namespace Nuxed\EventDispatcher;

final class EventDispatcher implements IEventDispatcher {
  private dict<
    classname<IEvent>,
    \SplPriorityQueue<(function(IEvent): Awaitable<void>)>,
  > $listeners = dict[];

  /**
   * Register an event listener with the dispatcher.
   */
  public function on<TEvent as IEvent>(
    classname<TEvent> $event,
    (function(TEvent): Awaitable<void>) $listener,
    int $priority = 0,
  ): void {
    $listeners = $this->listeners[$event] ??
      new \SplPriorityQueue<(function(IEvent): Awaitable<void>)>();
    $listeners->insert($listener, $priority);
    $this->listeners[$event] = $listeners;
  }

  /**
   * Register an event subscriber with the dispatcher.
   */
  public function subscribe(IEventSubscriber $subscriber): void {
    $subscriber->subscribe($this);
  }

  /**
   * Dispatch an event and call the listeners.
   */
  public async function dispatch<TEvent as IEvent>(
    TEvent $event,
  ): Awaitable<TEvent> {
    $ref = $event;
    if ($ref is IStoppableEvent && $ref->isPropagationStopped()) {
      // event is already stopped.
      return $event;
    }

    $name = \get_class($ref);
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
        if ($ref is IStoppableEvent && $ref->isPropagationStopped()) {
          $stopped = true;
          return;
        }

        return await $listener($ref);
      };
    }

    await $lastOperation;
    return $event;
  }

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<IEvent> $event): void {
    unset($this->listeners[$event]);
  }
}
