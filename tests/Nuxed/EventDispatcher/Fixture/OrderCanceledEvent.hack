namespace Nuxed\Test\EventDispatcher\Fixture;

use namespace Nuxed\EventDispatcher;

final class OrderCanceledEvent implements EventDispatcher\IStoppableEvent {
  public bool $handled = false;

  public function __construct(
    public string $orderId,
  ) {}

  public function isPropagationStopped(): bool {
    return $this->handled;
  }
}
