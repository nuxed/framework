namespace Nuxed\Http\Server\Handler;

use namespace Nuxed\Http\{Message, Server};

final class CallableHandlerDecorator implements Server\IHandler {
  public function __construct(
    private Server\CallableHandler $callback,
  ) {}

  public function handle(
    Message\ServerRequest $request,
  ): Awaitable<Message\Response> {
    $fun = $this->callback;
    return $fun($request);
  }
}
