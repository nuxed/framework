namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Router;

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
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    $routeResult = $request->getAttribute(Router\RouteResult::class);

    if ($routeResult is Router\RouteResult) {
      $route = $routeResult->getMatchedRoute();
      if ($route is nonnull) {
        return await $route->getMiddleware()->process($request, $handler);
      } else {
        return await $handler->handle($request);
      }
    }

    return await $handler->handle($request);
  }
}
