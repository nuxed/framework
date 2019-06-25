namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Http\{Message, Server};

class NotFoundHandler implements Server\IRequestHandler {
  public async function handle(
    Message\ServerRequest $_,
  ): Awaitable<Message\Response> {
    return new Message\Response\JsonResponse(
      dict[
        'status' => 'error',
        'message' => 'Not Found',
        'code' => 404,
      ],
      Message\StatusCode::STATUS_NOT_FOUND,
    );
  }
}
