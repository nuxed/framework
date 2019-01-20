namespace Nuxed\Http\Router;

use type Nuxed\Contract\Http\Router\RouterInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;

class RouteCollector {
  use RouteCollectorTrait;

  public function __construct(protected RouterInterface $router) {}

  public function route(
    string $path,
    MiddlewareInterface $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): Route {
    $this->checkForDuplicateRoute($path, $methods);

    $route = new Route($path, $middleware, $methods, $name);
    $this->routes[] = $route;
    $this->router->addRoute($route);
    return $route;
  }
}
