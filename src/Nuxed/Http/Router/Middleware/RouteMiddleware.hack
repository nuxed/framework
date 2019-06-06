namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Router;
use namespace Nuxed\Http\Message;

/**
 * Default routing middleware.
 *
 * Uses the composed router to match against the incoming request, and
 * injects the request passed to the handler with the `RouteResult` instance
 * returned (using the `RouteResult` class name as the attribute name).
 *
 * If routing succeeds, injects the request passed to the handler with any
 * matched parameters as well.
 */
class RouteMiddleware implements Server\IMiddleware {
  public function __construct(
    protected Router\Matcher\IRequestMatcher $matcher,
  ) {}

  public function process(
    Message\ServerRequest $request,
    Server\IRequestHandler $handler,
  ): Awaitable<Message\Response> {
    $result = $this->matcher->match($request);

    // Inject the actual route result, as well as individual matched parameters.
    $request = $request->withAttribute(Router\RouteResult::class, $result);

    if ($result->isSuccess()) {
      foreach ($result->getMatchedParams() as $param => $value) {
        $request = $request->withAttribute($param, $value);
      }
    }

    return $handler->handle($request);
  }
}
