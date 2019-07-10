namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace Nuxed\EventDispatcher;

/**
 * Mapper from an event to the listeners that are applicable to that event.
 */
interface IListenerProvider {
  /**
   * @template T as EventDispatcher\IEvent
   *
   * @param T $event
   *   An event for which to return the relevant listeners.
   * @return AsyncIterator<EventDispatcher\IEventListener<T>>
   *   An async iterator (usually an async generator) of listeners. Each
   *   listener MUST be type-compatible with $event.
   */
  public function getListeners<T as EventDispatcher\IEvent>(
    T $event,
  ): AsyncIterator<EventDispatcher\IEventListener<T>>;
}
