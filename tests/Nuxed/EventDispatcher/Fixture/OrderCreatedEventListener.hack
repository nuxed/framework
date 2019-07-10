namespace Nuxed\Test\EventDispatcher\Fixture;

use namespace Nuxed\EventDispatcher;

class OrderCreatedEventListener
  implements EventDispatcher\IEventListener<OrderCreatedEvent> {
  public async function process(OrderCreatedEvent $event): Awaitable<void> {
    throw new \Exception("Error Processing Event");
  }
}
