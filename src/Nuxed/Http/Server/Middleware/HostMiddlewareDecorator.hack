namespace Nuxed\Http\Server\Middleware;

use namespace HH\Lib\Str;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;

class HostMiddlewareDecorator implements MiddlewareInterface {
  public function __construct(
    private string $host,
    private MiddlewareInterface $middleware,
  ) {}

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $host = $request->getUri()->getHost();

    if ($host !== Str\lowercase($this->host)) {
      return await $handler->handle($request);
    }

    return await $this->middleware->process($request, $handler);
  }
}
