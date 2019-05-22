namespace Nuxed\Kernel\Middleware;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Kernel\Error;

class ErrorMiddleware implements Server\IMiddleware {
  public function __construct(private Error\IErrorHandler $handler) {}

  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    try {
      return await $handler->handle($request);
    } catch (\Throwable $e) {
      return await $this->handler->handle($e, $request);
    }
  }
}
