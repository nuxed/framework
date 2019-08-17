namespace Nuxed\Http\Server\RequestHandler;

use namespace Nuxed\Http\{Message, Server};

class NotFoundHandler implements Server\IRequestHandler {
  public async function handle(
    Message\ServerRequest $_request,
  ): Awaitable<Message\Response> {
    throw new Server\Exception\NotFoundException();
  }
}
