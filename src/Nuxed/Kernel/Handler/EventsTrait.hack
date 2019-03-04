namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Contract\Event;

trait EventsTrait {
  use ServicesTrait;

  protected function dispatch<TEvent as Event\EventInterface>(
    TEvent $event,
  ): Awaitable<TEvent> {
    return $this->getService(Event\EventDispatcherInterface::class)
      ->dispatch($event);
  }
}
