namespace Nuxed\Kernel\Event;

use namespace Nuxed\Http\Message;
use namespace Nuxed\EventDispatcher;

class HandleEvent implements EventDispatcher\IEvent {
  public function __construct(public Message\ServerRequest $request) {}
}
