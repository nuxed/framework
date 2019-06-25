namespace Nuxed\Kernel\Event;

use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Http\{Message, Server};

final class ProcessEvent implements EventDispatcher\IEvent {
  public function __construct(
    public Message\ServerRequest $request,
    public Server\IRequestHandler $handler,
  ) {}
}
