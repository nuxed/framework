namespace Nuxed\Http\Server\Middleware;

use namespace Nuxed\Http\{Message, Server};

class OriginalMessagesMiddleware implements Server\IMiddleware {
  public async function process(
    Message\ServerRequest $request,
    Server\IHandler $handler,
  ): Awaitable<Message\Response> {
    return await $handler->handle(
      $request
        ->withAttribute('OriginalUri', $request->getUri())
        ->withAttribute('OriginalRequest', $request),
    );
  }
}
