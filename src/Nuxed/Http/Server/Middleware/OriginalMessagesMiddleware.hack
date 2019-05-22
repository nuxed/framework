namespace Nuxed\Http\Server\Middleware;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Server;

class OriginalMessagesMiddleware implements Server\IMiddleware {
  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    return await $handler->handle(
      $request
        ->withAttribute('OriginalUri', $request->getUri())
        ->withAttribute('OriginalRequest', $request),
    );
  }
}
