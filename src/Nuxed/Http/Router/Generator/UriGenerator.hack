namespace Nuxed\Http\Router\Generator;

use namespace HH\Lib\C;
use namespace Nuxed\Util;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace Nuxed\Http\Router;
use namespace Nuxed\Http\Server;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Router\Exception;
use namespace Facebook\HackRouter;
use namespace Facebook\HackRouter\PatternParser;

class UriGenerator implements IUriGenerator {
  public function __construct(private Router\IRouteCollector $collector) {}

  /**
   * Generate a URI from the named route.
   *
   * Takes the named route and any substitutions, and attempts to generate a
   * URI from it.
   *
   * The URI generated MUST NOT be escaped. If you wish to escape any part of
   * the URI, this should be performed afterwards;
   */
  public function generate(
    string $route,
    KeyedContainer<string, mixed> $substitutions = dict[],
  ): Message\Uri {
    $routes = Dict\from_values(
      $this->collector->getRoutes(),
      ($route) ==> $route->getName(),
    );
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
        } else if ($node is PatternParser\ParameterNode) {
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
          } else if ($value is int) {
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
        } else if ($value is string) {
          $uriBuilder->setString($key, $value);
        } else {
          $uriBuilder->setEnum(\get_class($value), $key, $value);
        }
      }

      return new Message\Uri($uriBuilder->getPath());
    } catch (\Exception $e) {
      if (!$e is Exception\IException) {
        $e = new Exception\RuntimeException(
          $e->getMessage(),
          $e->getCode(),
          $e,
        );
      }

      throw $e;
    }
  }

}
