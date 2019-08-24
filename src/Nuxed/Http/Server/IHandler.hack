namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Message;

/**
 * An HTTP request handler process a HTTP request and produces an HTTP response.
 * This interface defines the methods require to use the request handler.
 */
interface IHandler {
  /**
   * Handle the request and return a response.
   */
  public function handle(
    Message\ServerRequest $request,
  ): Awaitable<Message\Response>;
}
