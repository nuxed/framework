namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Http\{Message, Router, Server};

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
class MethodNotAllowedMiddleware implements Server\IMiddleware {
  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    $routeResult = $request->getAttribute(Router\RouteResult::class);

    if (
      !$routeResult is Router\RouteResult || !$routeResult->isMethodFailure()
    ) {
      return await $handler->handle($request);
    }

    return Message\response()
      ->withStatus(Message\StatusCode::STATUS_METHOD_NOT_ALLOWED)
      ->withHeader('Allow', $routeResult->getAllowedMethods() as nonnull);
  }
}
