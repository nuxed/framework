namespace Nuxed\Kernel\Event;

use namespace Nuxed\Http\Message;
use namespace Nuxed\EventDispatcher;

final class EmitEvent implements EventDispatcher\IEvent {
  public function __construct(public Message\Response $response) {}
}
