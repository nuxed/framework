<?hh // strict

namespace Nuxed\Contract\Event;

use type Nuxed\Contract\Service\ResetInterface;

interface EventDispatcherInterface extends ResetInterface {
  /**
   * Register an event listener with the dispatcher.
   */
  public function on(
    classname<EventInterface> $event,
    EventListener $listener,
    int $priority = 0,
  ): void;

  /**
   * Register an event subscriber with the dispatcher.
   */
  public function subscribe(EventSubscriberInterface $subscriber): void;

  /**
   * Dispatch an event and call the listeners.
   */
  public function dispatch<TEvent as EventInterface>(TEvent $event): TEvent;

  /**
   * Remove a set of listeners from the dispatcher.
   */
  public function forget(classname<EventInterface> $event): void;
}
