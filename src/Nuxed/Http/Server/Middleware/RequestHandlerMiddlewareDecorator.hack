namespace Nuxed\Http\Server\Middleware;

use namespace Nuxed\Http\{Message, Server};

/**
 * Decorate a request handler as middleware.
 *
 * When pulling handlers from a container, or creating pipelines, it's
 * simplest if everything is of the same type, so we do not need to worry
 * about varying execution based on type.
 *
 * To manage this, this class decorates request handlers as middleware, so that
 * they may be piped or routed to. When processed, they delegate handling to the
 * decorated handler, which will return a response.
 */
final class RequestHandlerMiddlewareDecorator
  implements Server\IMiddleware, Server\IRequestHandler {
  public function __construct(private Server\IRequestHandler $handler) {}

  /**
   * Proxies to decorated handler to handle the request.
   */
  public function handle(
    Message\ServerRequest $request,
  ): Awaitable<Message\Response> {
    return $this->handler->handle($request);
  }

  /**
   * Proxies to decorated handler to handle the request.
   */
  public function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $_,
  ): Awaitable<Message\Response> {
    return $this->handler->handle($request);
  }
}
