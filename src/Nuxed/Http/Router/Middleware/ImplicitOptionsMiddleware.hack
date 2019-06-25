namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Http\{Message, Router, Server};

/**
 * Handle implicit OPTIONS requests.
 *
 * Place this middleware after the routing middleware so that it can handle
 * implicit OPTIONS requests: requests where OPTIONS is used, but the route
 * does not explicitly handle that request method.
 *
 * When invoked, it will create a response with status code 200 and an Allow
 * header that defines all accepted request methods.
 *
 * You may optionally pass a response prototype to the constructor; when
 * present, that prototype will be used to create a new response with the
 * Allow header.
 *
 * The middleware is only invoked in these specific conditions:
 *
 * - an OPTIONS request
 * - with a `RouteResult` present
 * - where the `RouteResult` contains a `Route` instance
 * - and the `Route` instance defines implicit OPTIONS.
 *
 * In all other circumstances, it will return the result of the delegate.
 */
class ImplicitOptionsMiddleware implements Server\IMiddleware {
  /**
   * Handle an implicit OPTIONS request.
   */
  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    if ($request->getMethod() !== Message\RequestMethod::METHOD_OPTIONS) {
      return await $handler->handle($request);
    }

    $result = $request->getAttribute(Router\RouteResult::class);

    if (!$result is Router\RouteResult) {
      return await $handler->handle($request);
    }

    if ($result->isFailure() && !$result->isMethodFailure()) {
      return await $handler->handle($request);
    }

    if ($result->getMatchedRoute()) {
      return await $handler->handle($request);
    }

    $allowedMethods = $result->getAllowedMethods();

    return Message\response()
      ->withHeader('Allow', $allowedMethods ?? vec[]);
  }
}
