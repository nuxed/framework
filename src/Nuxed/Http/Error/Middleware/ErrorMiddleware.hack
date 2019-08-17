namespace Nuxed\Http\Error\Middleware;

use namespace Nuxed\Http\{Error, Message, Server};

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
