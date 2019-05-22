namespace Nuxed\Kernel\Event;

use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Http\Message;

class TerminateEvent implements EventDispatcher\IEvent {
  public function __construct(
    public Message\ServerRequest $request,
    public Message\Response $response,
  ) {}
}
