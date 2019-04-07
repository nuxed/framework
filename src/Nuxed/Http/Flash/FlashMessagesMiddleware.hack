namespace Nuxed\Http\Flash;

use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;

final class FlashMessagesMiddleware implements MiddlewareInterface {
  public function __construct(
    private string $key = FlashMessages::FLASH_NEXT,
  ) {}

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $session = $request->getAttribute('session') as SessionInterface;
    $flash = FlashMessages::create($session, $this->key);
    return await $handler->handle($request->withAttribute('flash', $flash));
  }
}
