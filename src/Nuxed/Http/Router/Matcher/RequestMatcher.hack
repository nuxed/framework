namespace Nuxed\Http\Router\Matcher;

use namespace Nuxed\Http\Router;
use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace Nuxed\Util;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace Nuxed\Cache;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use namespace Facebook\HackRouter;
use namespace Facebook\TypeSpec;
use namespace Facebook\HackRouter\PatternParser;

class RequestMatcher implements IRequestMatcher {
  const string CACHE_KEY = 'nuxed.http.router.matcher.request_matcher.cache';

  private ?HackRouter\IResolver<Router\Route> $resolver;

  public function __construct(
    protected Router\IRouteCollector $collector,
    protected ?Cache\ICache $cache = null,
  ) {}

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
        return Router\RouteResult::fromRouteFailure([]);
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

    $cache = $this->cache;
    if ($cache is null) {
      $routes = null;
    } else {
      $routes = Asio\join($cache->contains(self::CACHE_KEY))
        ? Asio\join($cache->get(self::CACHE_KEY))
        : null;
    }

    if ($routes is null) {
      $routes = Router\_Private\map($this->collector->getRoutes());

      if ($cache is nonnull) {
        Asio\join($cache->put(self::CACHE_KEY, $routes));
      }
    }

    /* HH_IGNORE_ERROR[4110] */
    $this->resolver = new HackRouter\PrefixMatchingResolver(dict($routes));

    return $this->resolver;
  }
}
