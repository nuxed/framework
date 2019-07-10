namespace Nuxed\Test\EventDispatcher\Fixture;

use namespace Nuxed\EventDispatcher;

final class OrderCanceledEventListener
  implements EventDispatcher\IEventListener<OrderCanceledEvent> {

  public function __construct(
    public string $append,
    private bool $handle = false,
  ) {}

  public async function process(OrderCanceledEvent $event): Awaitable<void> {
    $event->orderId .= $this->append;
    if ($this->handle) {
      $event->handled = true;
    }
  }
}
