namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Http\{Message, Router, Server};


/**
 * Handle implicit HEAD requests.
 *
 * Place this middleware after the routing middleware so that it can handle
 * implicit HEAD requests: requests where HEAD is used, but the route does
 * not explicitly handle that request method.
 *
 * When invoked, it will create an empty response with status code 200.
 *
 * You may optionally pass a response prototype to the constructor; when
 * present, that instance will be returned instead.
 *
 * The middleware is only invoked in these specific conditions:
 *
 * - a HEAD request
 * - with a `RouteResult` present
 * - where the `RouteResult` contains a `Route` instance
 * - and the `Route` instance defines implicit HEAD.
 *
 * In all other circumstances, it will return the result of the delegate.
 *
 * If the route instance supports GET requests, the middleware dispatches
 * the next layer, but alters the request passed to use the GET method;
 * it then provides an empty response body to the returned response.
 */
class ImplicitHeadMiddleware implements Server\IMiddleware {
  const string FORWARDED_HTTP_METHOD_ATTRIBUTE = 'FORWARDED_HTTP_METHOD';

  public function __construct(
    private Router\Matcher\IRequestMatcher $matcher,
  ) {}

  /**
   * Handle an implicit HEAD request.
   *
   * If the route allows GET requests, dispatches as a GET request and
   * resets the response body to be empty; otherwise, creates a new empty
   * response.
   */
  public async function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    if ($request->getMethod() !== Message\RequestMethod::METHOD_HEAD) {
      return await $handler->handle($request);
    }

    $result = $request->getAttribute(Router\RouteResult::class);

    if (!$result is Router\RouteResult) {
      return await $handler->handle($request);
    }

    if (null !== $result->getMatchedRoute()) {
      return await $handler->handle($request);
    }

    $routeResult = $this->matcher
      ->match($request->withMethod(Message\RequestMethod::METHOD_GET));

    if ($routeResult->isFailure()) {
      return await $handler->handle($request);
    }

    // Copy matched parameters like RouteMiddleware does
    foreach ($routeResult->getMatchedParams() as $param => $value) {
      $request = $request->withAttribute($param, $value);
    }

    $response = await $handler->handle(
      $request
        ->withAttribute(Router\RouteResult::class, $routeResult)
        ->withMethod(Message\RequestMethod::METHOD_GET)
        ->withAttribute(
          self::FORWARDED_HTTP_METHOD_ATTRIBUTE,
          Message\RequestMethod::METHOD_HEAD,
        ),
    );

    return $response->withBody(Message\stream(''));
  }
}
