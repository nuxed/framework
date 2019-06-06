namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

trait RequestHandlerMiddlewareTrait implements IMiddleware {
  require implements IRequestHandler;

  public function process(
    Message\ServerRequest $request,
    IRequestHandler $_handler,
  ): Awaitable<Message\Response> {
    return $this->handle($request);
  }
}
