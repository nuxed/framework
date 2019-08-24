namespace Nuxed\Http\Server\Middleware;

use namespace Nuxed\Http\{Message, Server};

final class CallableMiddlewareDecorator implements Server\IMiddleware {
  public function __construct(private Server\CallableMiddleware $middleware) {}

  public function process(
    Message\ServerRequest $request,
    Server\IHandler $handler,
  ): Awaitable<Message\Response> {
    $fun = $this->middleware;
    return $fun($request, $handler);
  }
}
