namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Http\Message;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;

class NotFoundHandler implements RequestHandlerInterface {
  public async function handle(
    ServerRequestInterface $_request,
  ): Awaitable<ResponseInterface> {
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
