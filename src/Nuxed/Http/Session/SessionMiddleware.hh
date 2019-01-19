<?hh // strict

namespace Nuxed\Http\Session;

use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;

class SessionMiddleware implements MiddlewareInterface {
  public function __construct(
    private Persistence\SessionPersistenceInterface $persistence,
  ) {}

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $session = $this->persistence->initialize($request);
    $response =
      await $handler->handle($request->withAttribute('session', $session));

    return $this->persistence->persist($session, $response);
  }
}
