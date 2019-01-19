<?hh // strict

namespace Nuxed\Http\Router\Middleware;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteResultInterface;
use type Nuxed\Contract\Http\Router\RouterInterface;

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
class RouteMiddleware implements MiddlewareInterface {
  public function __construct(protected RouterInterface $router) {}

  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $result = $this->router->match($request);

    // Inject the actual route result, as well as individual matched parameters.
    $request = $request->withAttribute(RouteResultInterface::class, $result);

    if ($result->isSuccess()) {
      foreach ($result->getMatchedParams() as $param => $value) {
        $request = $request->withAttribute($param, $value);
      }
    }

    return $handler->handle($request);
  }
}
