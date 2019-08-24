namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Http\{Message, Router, Server};

/**
 * Default dispatch middleware.
 *
 * Checks for a composed route result in the request. If none is provided,
 * delegates request processing to the handler.
 *
 * Otherwise, it delegates processing to the route result.
 */
class DispatchMiddleware implements Server\IMiddleware {
  public async function process(
    Message\ServerRequest $request,
    Server\IHandler $handler,
  ): Awaitable<Message\Response> {
    $routeResult = $request->getAttribute(Router\RouteResult::class);

    if ($routeResult is Router\RouteResult) {
      $route = $routeResult->getMatchedRoute();
      if ($route is nonnull) {
        return await $route->getMiddleware()->process($request, $handler);
      }
    }

    return await $handler->handle($request);
  }
}
