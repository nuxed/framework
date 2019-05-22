namespace Nuxed\Kernel\Event;

use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Http\Message;

final class ErrorEvent
  implements EventDispatcher\IEvent, EventDispatcher\IStoppableEvent {
  public ?Message\Response $response;

  public function __construct(
    public \Throwable $error,
    public Message\ServerRequest $request,
  ) {}

  public function isPropagationStopped(): bool {
    return $this->response is nonnull;
  }
}
