namespace Nuxed\Http\Server\Handler;

use namespace Nuxed\Http\{Message, Server};

class NotFoundHandler implements Server\IHandler {
  public async function handle(
    Message\ServerRequest $_request,
  ): Awaitable<Message\Response> {
    throw new Server\Exception\ServerException(404, dict[]);
  }
}
