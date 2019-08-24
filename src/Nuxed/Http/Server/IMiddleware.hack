namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

/**
 * An HTTP middleware component participates in processing an HTTP message,
 * either by acting on the request or the response. This interface defines the
 * methods required to use the middleware.
 */
interface IMiddleware {
  /**
   * Process an incoming server request and return a response, optionally delegating
   * response creation to a handler.
   */
  public function process(
    Message\ServerRequest $request,
    IHandler $handler,
  ): Awaitable<Message\Response>;
}
