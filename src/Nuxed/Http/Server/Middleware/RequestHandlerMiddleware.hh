<?hh // strict

namespace Nuxed\Http\Server\Middleware;

use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;

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
final class RequestHandlerMiddleware
  implements MiddlewareInterface, RequestHandlerInterface {
  public function __construct(private RequestHandlerInterface $handler) {}

  /**
   * Proxies to decorated handler to handle the request.
   */
  public function handle(ServerRequestInterface $request): ResponseInterface {
    return $this->handler->handle($request);
  }

  /**
   * Proxies to decorated handler to handle the request.
   */
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $_,
  ): ResponseInterface {
    return $this->handler->handle($request);
  }
}
