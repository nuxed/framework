namespace Nuxed\EventDispatcher;

interface IEventDispatcher {
  /**
   * Register an event listener with the dispatcher.
   */
  public function on<TEvent as IEvent>(
    classname<TEvent> $event,
    (function(TEvent): Awaitable<void>) $listener,
    int $priority = 0,
  ): void;

  /**
   * Register an event subscriber with the dispatcher.
   */
  public function subscribe(IEventSubscriber $subscriber): void;

  /**
   * Dispatch an event and call the listeners.
   */
  public function dispatch<TEvent as IEvent>(TEvent $event): Awaitable<TEvent>;

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<IEvent> $event): void;
}
