<?hh // strict

namespace Nuxed\Http\Router\Middleware;

use type Nuxed\Http\Message\RequestMethod;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ResponseFactoryInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Router\RouteResultInterface;

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
class ImplicitOptionsMiddleware implements MiddlewareInterface {
  public function __construct(
    private ResponseFactoryInterface $responseFactory,
  ) {}

  /**
   * Handle an implicit OPTIONS request.
   */
  public function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): ResponseInterface {
    if ($request->getMethod() !== RequestMethod::METHOD_OPTIONS) {
      return $handler->handle($request);
    }

    $result = $request->getAttribute(RouteResultInterface::class);

    if (!$result is RouteResultInterface) {
      return $handler->handle($request);
    }

    if ($result->isFailure() && !$result->isMethodFailure()) {
      return $handler->handle($request);
    }

    if ($result->getMatchedRoute()) {
      return $handler->handle($request);
    }

    $allowedMethods = $result->getAllowedMethods();

    return $this->responseFactory
      ->createResponse()
      ->withHeader('Allow', $allowedMethods ?? vec[]);
  }
}
