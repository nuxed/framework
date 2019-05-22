namespace Nuxed\EventDispatcher;

interface IEventSubscriber {
  /*
   * Subscribe to the event dispatcher.
   */
  public function subscribe(IEventDispatcher $events): void;
}
