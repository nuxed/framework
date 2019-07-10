namespace Nuxed\EventDispatcher\ListenerProvider;

use namespace Nuxed\EventDispatcher;

interface IReifiedListenerProvider extends IListenerProvider {
  /**
   * Attach a listener
   *
   * Note: IReifiedListenerProvider::listen must use reified generics.
   *
   * use RefiedGenerics\getClassname<T> to determine the event type.
   */
  public function listen<<<__Enforceable>> T as EventDispatcher\IEvent>(
    EventDispatcher\IEventListener<T> $listener,
  ): void;
}
