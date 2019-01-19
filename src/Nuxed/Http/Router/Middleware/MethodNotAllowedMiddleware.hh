<?hh // strict

namespace Nuxed\Http\Router\Middleware;

use type Nuxed\Http\Message\StatusCode;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ResponseFactoryInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteResultInterface;

/**
 * Emit a 405 Method Not Allowed response
 *
 * If the request composes a route result, and the route result represents a
 * failure due to request method, this middleware will emit a 405 response,
 * along with an Allow header indicating allowed methods, as reported by the
 * route result.
 *
 * If no route result is composed, and/or it's not the result of a method
 * failure, it passes handling to the provided handler.
 */
class MethodNotAllowedMiddleware implements MiddlewareInterface {
  public function __construct(
    private ResponseFactoryInterface $responseFactory,
  ) {}

  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $routeResult = $request->getAttribute(RouteResultInterface::class);

    if (
      !$routeResult is RouteResultInterface || !$routeResult->isMethodFailure()
    ) {
      return await $handler->handle($request);
    }

    return $this->responseFactory
      ->createResponse()
      ->withStatus(StatusCode::STATUS_METHOD_NOT_ALLOWED)
      ->withHeader('Allow', $routeResult->getAllowedMethods() ?? vec[]);
  }
}
