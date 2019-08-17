namespace Nuxed\Http\Router\Matcher;

use namespace HH\Lib\{C, Dict, Vec};
use namespace Nuxed\Http\{Message, Router};
use namespace Facebook\HackRouter;

class RequestMatcher implements IRequestMatcher {
  private ?HackRouter\IResolver<Router\Route> $resolver;

  public function __construct(protected Router\IRouteCollector $collector) {}

  /**
   * Match a request against the known routes.
   *
   * Implementations will aggregate required information from the provided
   * request instance, and pass them to the underlying router implementation;
   * when done, they will then marshal a `Router\RouteResult` instance indicating
   * the results of the matching operation and return it to the caller.
   */
  public function match(Message\Request $request): Router\RouteResult {
    $method = HackRouter\HttpMethod::assert($request->getMethod());
    $path = $request->getUri()->getPath();
    $resolver = $this->getResolver();
    try {
      list($route, $data) = $resolver->resolve($method, $path);
      $data = Dict\map($data, $value ==> \urldecode($value));
      return Router\RouteResult::fromRoute($route, $data);
    } catch (HackRouter\NotFoundException $e) {
      $allowed = vec[];
      foreach (HackRouter\HttpMethod::getValues() as $next) {
        if ($next === $method) {
          continue;
        }
        try {
          list($responder, $data) = $resolver->resolve($next, $path);
          $allowed[] = $next;
        } catch (HackRouter\NotFoundException $_) {
          continue;
        }
      }

      if (C\count($allowed) === 0) {
        return Router\RouteResult::fromRouteFailure(null);
      }

      return Router\RouteResult::fromRouteFailure(
        Vec\map($allowed, ($method) ==> (string)$method),
      );
    }
  }

  private function getResolver(): HackRouter\IResolver<Router\Route> {
    if ($this->resolver is nonnull) {
      return $this->resolver;
    }

    $routes = Router\_Private\map($this->collector->getRoutes());
    $this->resolver = new HackRouter\PrefixMatchingResolver(dict($routes));

    return $this->resolver;
  }
}
