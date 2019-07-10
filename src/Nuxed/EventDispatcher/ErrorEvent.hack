namespace Nuxed\EventDispatcher;

use namespace HH\ReifiedGenerics;

final class ErrorEvent<reify T as IEvent> extends \Exception implements IEvent {
  public function __construct(
    private T $event,
    private IEventListener<T> $listener,
    private \Exception $e,
  ) {
    parent::__construct($e->getMessage(), $e->getCode(), $e);
  }

  public function getEventType(): classname<T> {
    /* HH_FIXME[2049] */
    /* HH_FIXME[4107] */
    return ReifiedGenerics\getClassname<T>();
  }

  public function getEvent(): T {
    return $this->event;
  }

  public function getListener(): IEventListener<T> {
    return $this->listener;
  }

  public function getException(): \Exception {
    return $this->e;
  }
}
