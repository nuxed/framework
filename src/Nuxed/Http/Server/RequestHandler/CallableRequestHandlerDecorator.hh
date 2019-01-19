<?hh // strict

namespace Nuxed\Http\Server\RequestHandler;

use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;

final class CallableRequestHandlerDecorator implements RequestHandlerInterface {
  public function __construct(
    private (function(ServerRequestInterface): ResponseInterface) $callback,
  ) {}

  public async function handle(
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface> {
    $fun = $this->callback;

    return $fun($request);
  }
}
