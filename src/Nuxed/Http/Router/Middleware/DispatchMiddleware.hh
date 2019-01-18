<?hh // strict

namespace Nuxed\Http\Router\Middleware;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteResultInterface;

/**
 * Default dispatch middleware.
 *
 * Checks for a composed route result in the request. If none is provided,
 * delegates request processing to the handler.
 *
 * Otherwise, it delegates processing to the route result.
 */
class DispatchMiddleware implements MiddlewareInterface {
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    $routeResult = $request->getAttribute(RouteResultInterface::class);

    if ($routeResult is RouteResultInterface) {
      $route = $routeResult->getMatchedRoute();
      if ($route is nonnull) {
        return $route->getMiddleware()->process($request, $handler);
      } else {
        return $handler->handle($request);
      }
    }

    return $handler->handle($request);
  }
}
