namespace Nuxed\Kernel;

use namespace Nuxed\Http\Emitter;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;

interface IKernel
  extends Server\IMiddleware, Server\IRequestHandler, Emitter\IEmitter {
  /**
   * Perform any final actions for the request lifecycle.
   */
  public function terminate(
    Message\ServerRequest $request,
    Message\Response $response,
  ): Awaitable<void>;
}
