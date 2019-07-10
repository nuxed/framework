namespace Nuxed\Test\EventDispatcher\Fixture;

use namespace Nuxed\EventDispatcher;

final class OrderCreatedEvent implements EventDispatcher\IEvent {
  public function __construct(public string $orderId) {}
}
