namespace Nuxed\EventDispatcher;

final class CallableEventListener<T as IEvent> implements IEventListener<T> {
  public function __construct(
    private (function(T): Awaitable<void>) $listener,
  ) {}

  public function process(T $event): Awaitable<void> {
    return ($this->listener)($event);
  }
}
