namespace Nuxed\Contract\Http\Server;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;

/**
 * An HTTP request handler process a HTTP request and produces an HTTP response.
 * This interface defines the methods require to use the request handler.
 */
interface RequestHandlerInterface {
  /**
   * Handle the request and return a response.
   */
  public function handle(
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface>;
}
