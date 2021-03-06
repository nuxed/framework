namespace Nuxed\Http\Session;

use type Nuxed\Http\Server\{IHandler, IMiddleware};
use type Nuxed\Http\Message\{Response, ServerRequest};

class SessionMiddleware implements IMiddleware {
  public function __construct(
    private Persistence\ISessionPersistence $persistence,
  ) {}

  public async function process(
    ServerRequest $request,
    IHandler $handler,
  ): Awaitable<Response> {
    $session = await $this->persistence->initialize($request);
    $request = $request->withSession($session);
    $response = await $handler->handle($request);

    return await $this->persistence->persist($request->getSession(), $response);
  }
}
