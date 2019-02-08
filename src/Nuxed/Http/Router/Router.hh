<?hh // strict

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
use type Nuxed\Http\Message\Uri;
use type Exception;
use function preg_match;
use function get_class;

class Router implements RouterInterface {
  public function __construct(
    private dict<string, RouteInterface> $routes = dict[],
  ) {}

  public function addRoute(RouteInterface $route): void {
    $this->routes[$route->getName()] = $route;
  }

  public function match(RequestInterface $request): RouteResultInterface {
    $method = $request->getMethod();
    $path = $request->getUri()->getPath();
    $routes = $this->marshalMethodRoutes($method);

    if (0 !== C\count($routes)) {

      try {
        $prefixMap = PrefixMatching\PrefixMap::fromFlatMap(dict($routes));
        list($route, $params) = $this->resolveWithMap($path, $prefixMap);

        return RouteResult::fromRoute($route, $params);
      } catch (HackRouter\NotFoundException $e) {
      }
    }

    $allowedMethods = vec[];
    $prefixMap =
      PrefixMatching\PrefixMap::fromFlatMap(dict($this->map($this->routes)));

    try {
      list($route, $params) = $this->resolveWithMap($path, $prefixMap);
      $allowedMethods = $route->getAllowedMethods();
      return RouteResult::fromRouteFailure($allowedMethods);
    } catch (HackRouter\NotFoundException $e) {
      return RouteResult::fromRouteFailure(null);
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
    if (!C\contains_key($this->routes, $route)) {
      $message = Str\format('Route %s doesn\'t exist', $route);
      $alternatives = Util\alternatives($route, Vec\keys($this->routes));
      if (0 !== C\count($alternatives)) {
        $message .=
          Str\format(', did you mean %s.', Str\join($alternatives, ', '));
      } else {
        $message .= '.';
      }
      throw new Exception\InvalidArgumentException($message);
    }

    try {
      $route = $this->routes[$route];
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
              get_class($value),
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
          $uriBuilder->setEnum(get_class($value), $key, $value);
        }
      }

      return new Uri($uriBuilder->getPath());
    } catch (Exception $e) {
      if (!$e is Exception\ExceptionInterface) {
        $e =
          new Exception\RuntimeException($e->getMessage(), $e->getCode(), $e);
      }
      throw $e;
    }
  }

  protected function marshalMethodRoutes(
    string $method,
  ): KeyedContainer<string, RouteInterface> {
    $routes = dict[];
    $method = Str\uppercase($method);

    $ret = vec[];
    foreach ($this->routes as $route) {
      $allowedMethods = $route->getAllowedMethods();

      if (null === $allowedMethods || C\contains($allowedMethods, $method)) {
        $ret[] = $route;
      }
    }

    return $this->map($ret);
  }

  private function map(
    Container<RouteInterface> $routes,
  ): KeyedContainer<string, RouteInterface> {
    $ret = dict[];
    foreach ($routes as $route) {
      $ret[$route->getPath()] = $route;
    }
    return $ret;
  }

  private function resolveWithMap(
    string $path,
    PrefixMatching\PrefixMap<RouteInterface> $map,
  ): (RouteInterface, KeyedContainer<string, mixed>) {
    $literals = $map->getLiterals();
    if (C\contains_key($literals, $path)) {
      return tuple($literals[$path], dict[]);
    }

    $prefixes = $map->getPrefixes();
    if (0 !== C\count($prefixes)) {
      $prefix_len = Str\length(C\first_keyx($prefixes));
      $prefix = Str\slice($path, 0, $prefix_len);

      if (C\contains_key($prefixes, $prefix)) {
        return $this->resolveWithMap(
          Str\strip_prefix($path, $prefix),
          $prefixes[$prefix],
        );
      }
    }

    $regexps = $map->getRegexps();

    foreach ($regexps as $regexp => $sub_map) {
      $pattern = '#^'.$regexp.'#';
      $matches = [];

      /**
       * @todo [Http][Router] use hsl regex
       * @body this is an issue with hack-router since it use string instead of regex pattern, its not possible to use hsl regex.
       */
      if (preg_match($pattern, $path, &$matches) !== 1) {
        continue;
      }

      $matched = $matches[0];
      $remaining = Str\strip_prefix($path, $matched);

      $data = Dict\filter_keys($matches, ($key) ==> $key is string);
      $sub = $regexps[$regexp];

      if ($sub->isResponder()) {
        if ($remaining === '') {
          return tuple($sub->getResponder(), $data);
        }

        continue;
      }

      try {
        list($responder, $sub_data) =
          $this->resolveWithMap($remaining, $sub->getMap());
      } catch (HackRouter\NotFoundException $_) {
        continue;
      }

      return tuple($responder, Dict\merge($data, $sub_data));
    }

    throw new HackRouter\NotFoundException();
  }
}
