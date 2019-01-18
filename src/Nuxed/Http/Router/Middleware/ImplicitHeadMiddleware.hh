<?hh // strict

namespace Nuxed\Http\Router\Middleware;

use type Nuxed\Http\Message\RequestMethod;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\StreamFactoryInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteResultInterface;
use type Nuxed\Contract\Http\Router\RouterInterface;

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
class ImplicitHeadMiddleware implements MiddlewareInterface {
  const string FORWARDED_HTTP_METHOD_ATTRIBUTE = 'FORWARDED_HTTP_METHOD';

  public function __construct(
    private RouterInterface $router,
    private StreamFactoryInterface $streamFactory,
  ) {}

  /**
   * Handle an implicit HEAD request.
   *
   * If the route allows GET requests, dispatches as a GET request and
   * resets the response body to be empty; otherwise, creates a new empty
   * response.
   */
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    if ($request->getMethod() !== RequestMethod::METHOD_HEAD) {
      return $handler->handle($request);
    }

    $result = $request->getAttribute(RouteResultInterface::class);

    if (!$result is RouteResultInterface) {
      return $handler->handle($request);
    }

    if (null !== $result->getMatchedRoute()) {
      return $handler->handle($request);
    }

    $routeResult = $this->router
      ->match($request->withMethod(RequestMethod::METHOD_GET));

    if ($routeResult->isFailure()) {
      return $handler->handle($request);
    }

    // Copy matched parameters like RouteMiddleware does
    foreach ($routeResult->getMatchedParams() as $param => $value) {
      $request = $request->withAttribute($param, $value);
    }

    $response = $handler->handle(
      $request
        ->withAttribute(RouteResultInterface::class, $routeResult)
        ->withMethod(RequestMethod::METHOD_GET)
        ->withAttribute(
          self::FORWARDED_HTTP_METHOD_ATTRIBUTE,
          RequestMethod::METHOD_HEAD,
        ),
    );

    return $response->withBody($this->streamFactory->createStream());
  }
}
