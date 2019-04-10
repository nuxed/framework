namespace Nuxed\Contract\Event;

interface EventDispatcherInterface {
  /**
   * Register an event listener with the dispatcher.
   */
  public function on<TEvent as EventInterface>(
    classname<TEvent> $event,
    (function(TEvent): Awaitable<void>) $listener,
    int $priority = 0,
  ): void;

  /**
   * Register an event subscriber with the dispatcher.
   */
  public function subscribe(EventSubscriberInterface $subscriber): void;

  /**
   * Dispatch an event and call the listeners.
   */
  public function dispatch<TEvent as EventInterface>(
    TEvent $event,
  ): Awaitable<TEvent>;

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<EventInterface> $event): void;
}
