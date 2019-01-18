<?hh // strict

namespace Nuxed\Contract\Event;

interface EventSubscriberInterface {
  /*
   * Subscribe to the event dispatcher.
   */
  public function subscribe(EventDispatcherInterface $events): void;
}
