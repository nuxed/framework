namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

trait HandlerMiddlewareTrait implements IMiddleware {
  require implements IHandler;

  public function process(
    Message\ServerRequest $request,
    IHandler $_handler,
  ): Awaitable<Message\Response> {
    return $this->handle($request);
  }
}
