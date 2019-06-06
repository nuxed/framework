namespace Nuxed\Http\Router\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Router;

class RouteMiddlewareFactory implements Container\IFactory<RouteMiddleware> {
  public function create(
    Container\IServiceContainer $container,
  ): RouteMiddleware {
    return new RouteMiddleware(
      $container->get(Router\Matcher\IRequestMatcher::class),
    );
  }
}
