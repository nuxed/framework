namespace Nuxed\EventDispatcher;

/**
 * Defines a listener for an event.
 */
interface IEventListener<T as IEvent> {
  /**
   * Process the given event.
   */
  public function process(T $event): Awaitable<void>;
}
