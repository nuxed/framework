namespace Nuxed\Http\Server\RequestHandler;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Server;

final class CallableRequestHandlerDecorator implements Server\IRequestHandler {
  public function __construct(
    private Server\CallableRequestHandler $callback,
  ) {}

  public function handle(
    Message\ServerRequest $request,
  ): Awaitable<Message\Response> {
    $fun = $this->callback;
    return $fun($request);
  }
}
