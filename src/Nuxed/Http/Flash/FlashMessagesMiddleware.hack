namespace Nuxed\Http\Flash;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;

final class FlashMessagesMiddleware implements Server\IMiddleware {
  public function __construct(
    private string $key = FlashMessages::FLASH_NEXT,
  ) {}

  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    $session = $request->getSession();
    $flash = FlashMessages::create($session, $this->key);
    return await $handler->handle($request->withFlash($flash));
  }
}
