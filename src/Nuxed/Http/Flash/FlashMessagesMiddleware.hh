<?hh // strict

namespace Nuxed\Http\Flash;

use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;

class FlashMessagesMiddleware implements MiddlewareInterface {
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    $session = $request->getAttribute('session') as SessionInterface;
    $flash = FlashMessages::create($session);
    return $handler->handle($request->withAttribute('flash', $flash));
  }
}
