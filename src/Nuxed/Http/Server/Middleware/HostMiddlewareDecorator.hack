namespace Nuxed\Http\Server\Middleware;

use namespace HH\Lib\Str;
use namespace Nuxed\Http\{Message, Server};

class HostMiddlewareDecorator implements Server\IMiddleware {
  public function __construct(
    private string $host,
    private Server\IMiddleware $middleware,
  ) {}

  public async function process(
    Message\ServerRequest $request,
    Server\IHandler $handler,
  ): Awaitable<Message\Response> {
    $host = $request->getUri()->getHost();

    if ($host !== Str\lowercase($this->host)) {
      return await $handler->handle($request);
    }

    return await $this->middleware->process($request, $handler);
  }
}
