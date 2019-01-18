<?hh // strict

namespace Nuxed\Http\Server\Middleware;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;

class OriginalMessagesMiddleware implements MiddlewareInterface {
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    return $handler->handle(
      $request
        ->withAttribute('OriginalUri', $request->getUri())
        ->withAttribute('OriginalRequest', $request),
    );
  }
}
