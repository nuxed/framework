namespace Nuxed\Kernel\Middleware;

use type Nuxed\Kernel\Error\ErrorHandlerInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Throwable;

class ErrorMiddleware implements MiddlewareInterface {
  public function __construct(private ErrorHandlerInterface $handler) {}

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    try {
      return await $handler->handle($request);
    } catch (Throwable $e) {
      return await $this->handler->handle($e, $request);
    }
  }
}
