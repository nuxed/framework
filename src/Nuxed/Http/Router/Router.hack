namespace Nuxed\Http\Router;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace Nuxed\Util;
use namespace Facebook\HackRouter;
use namespace Facebook\HackRouter\PatternParser;
use namespace Facebook\HackRouter\PrefixMatching;
use type Nuxed\Contract\Http\Router\RouterInterface;
use type Nuxed\Contract\Http\Router\RouteInterface;
use type Nuxed\Contract\Http\Router\RouteResultInterface;
use type Nuxed\Contract\Http\Message\UriInterface;
use type Nuxed\Contract\Http\Message\RequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Http\Message\Uri;
use function Facebook\AutoloadMap\Generated\is_dev;

final class Router implements RouterInterface {
  use RouteCollectorTrait;

  private ?HackRouter\IResolver<RouteInterface> $resolver;
  protected vec<RouteInterface> $routes;

  public function __construct(
    Container<RouteInterface> $routes = vec[],
  ) {
    $this->routes = vec($routes);
  }

  /**
   * Add a route.
   *
   * This method adds a route against which the underlying implementation may
   * match. Implementations MUST aggregate route instances, but MUST NOT use
   * the details to inject the underlying router until `match()` and/or
   * `generateUri()` is called.  This is required to allow consumers to
   * modify route instances before matching (e.g., to provide route options,
   * inject a name, etc.).
   *
   * The method MUST raise an Exception if called after either `match()`
   * or `generateUri()` have already been called, to ensure integrity of the
   * router between invocations of either of those methods.
   */
  public function addRoute(RouteInterface $route): void {
    $this->routes[] = $route;
  }

  /**
   * Add a route for the route middleware to match.
   *
   * Accepts a combination of a path and middleware, and optionally the HTTP methods allowed.
   *
   * @param null|Container<string> $methods HTTP method to accept; null indicates any.
   * @param null|string $name The name of the route.
   * @throws Exception\DuplicateRouteException if specification represents an existing route.
   */
  public function route(
    string $path,
    MiddlewareInterface $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): Route {
    $this->checkForDuplicateRoute($path, $methods);

    $route = new Route($path, $middleware, $methods, $name);
    $this->addRoute($route);
    return $route;
  }

  /**
   * Retrieve all directly registered routes with the application.
   */
  public function getRoutes(): Container<RouteInterface> {
    return $this->routes;
  }

  /**
   * Match a request against the known routes.
   *
   * Implementations will aggregate required information from the provided
   * request instance, and pass them to the underlying router implementation;
   * when done, they will then marshal a `RouteResult` instance indicating
   * the results of the matching operation and return it to the caller.
   */
  public function match(RequestInterface $request): RouteResultInterface {
    $method = HackRouter\HttpMethod::assert($request->getMethod());
    $path = $request->getUri()->getPath();
    $resolver = $this->getResolver();
    try {
      list($route, $data) = $resolver->resolve($method, $path);
      $data = Dict\map($data, $value ==> \urldecode($value));
      return RouteResult::fromRoute($route, $data);
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
        return RouteResult::fromRouteFailure([]);
      }

      return RouteResult::fromRouteFailure(
        Vec\map($allowed, ($method) ==> (string)$method),
      );
    }
  }

  /**
   * Generate a URI from the named route.
   *
   * Takes the named route and any substitutions, and attempts to generate a
   * URI from it.
   *
   * The URI generated MUST NOT be escaped. If you wish to escape any part of
   * the URI, this should be performed afterwards;
   */
  public function generateUri(
    string $route,
    KeyedContainer<string, mixed> $substitutions = dict[],
  ): UriInterface {
    $routes = Dict\from_values($this->routes, ($route) ==> $route->getName());
    if (!C\contains_key($routes, $route)) {
      $message = Str\format('Route %s doesn\'t exist', $route);
      $alternatives = Util\alternatives($route, Vec\keys($routes));
      if (0 !== C\count($alternatives)) {
        $message .= Str\format(
          ', did you mean %s.',
          Str\join($alternatives, ', '),
        );
      } else {
        $message .= '.';
      }
      throw new Exception\InvalidArgumentException($message);
    }

    try {
      $route = $routes[$route];
      $nodes = PatternParser\Parser::parse($route->getPath());
      $parts = vec[];

      foreach ($nodes->getChildren() as $node) {
        if ($node is PatternParser\LiteralNode) {
          $parts[] = new HackRouter\UriPatternLiteral($node->getText());
        } elseif ($node is PatternParser\ParameterNode) {
          if (!C\contains_key($substitutions, $node->getName())) {
            throw new Exception\InvalidArgumentException(
              Str\format('Missing parameter %s', $node->getName()),
            );
          }
          $value = $substitutions[$node->getName()];
          if ($value is string) {
            $parts[] = $part = new HackRouter\StringRequestParameter(
              $node->getRegexp() === '.+'
                ? HackRouter\StringRequestParameterSlashes::ALLOW_SLASHES
                : HackRouter\StringRequestParameterSlashes::WITHOUT_SLASHES,
              $node->getName(),
            );
            $part->assert($value);
          } elseif ($value is int) {
            $parts[] = new HackRouter\IntRequestParameter($node->getName());
          } else {
            $parts[] = new HackRouter\EnumRequestParameter(
              \get_class($value),
              $node->getName(),
            );
          }
        }
      }

      $uriBuilder = new HackRouter\UriBuilder($parts);
      foreach ($substitutions as $key => $value) {
        if ($value is int) {
          $uriBuilder->setInt($key, $value);
        } elseif ($value is string) {
          $uriBuilder->setString($key, $value);
        } else {
          $uriBuilder->setEnum(\get_class($value), $key, $value);
        }
      }

      return new Uri($uriBuilder->getPath());
    } catch (\Exception $e) {
      if (!$e is Exception\ExceptionInterface) {
        $e = new Exception\RuntimeException(
          $e->getMessage(),
          $e->getCode(),
          $e,
        );
      }

      throw $e;
    }
  }

  private function getResolver(): HackRouter\IResolver<RouteInterface> {
    if ($this->resolver is nonnull) {
      return $this->resolver;
    }

    if (is_dev()) {
      $routes = null;
    } else {
      $routes = \apc_fetch(__FILE__.'/cache');
      if ($routes === false) {
        $routes = null;
      }
    }

    if ($routes is null) {
      $routes = _Private\map($this->routes);
      
      if (!is_dev()) {
        \apc_store(__FILE__.'/cache', $routes);
      }
    }

    $this->resolver = new HackRouter\PrefixMatchingResolver(dict($routes));

    return $this->resolver;
  }
}
