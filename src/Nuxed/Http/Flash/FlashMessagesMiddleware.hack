namespace Nuxed\Http\Flash;

use namespace Nuxed\Http\{Message, Server};

final class FlashMessagesMiddleware implements Server\IMiddleware {
  public function __construct(
    private string $key = FlashMessages::FLASH_NEXT,
  ) {}

  public async function process(
    Message\ServerRequest $request,
    Server\IHandler $handler,
  ): Awaitable<Message\Response> {
    $session = $request->getSession();
    $flash = FlashMessages::create($session, $this->key);
    return await $handler->handle($request->withFlash($flash));
  }
}
