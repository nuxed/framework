namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Http\Server;

abstract class AbstractHandler implements Server\IRequestHandler {
  use HandlerTrait;
}
