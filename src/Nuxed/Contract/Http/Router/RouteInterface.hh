<?hh // strict

namespace Nuxed\Contract\Http\Router;

use type Nuxed\Contract\Http\Server\MiddlewareInterface;

/**
 * Value object representing a single route.
 *
 * Routes are a combination of path, middleware, and HTTP methods; two routes
 * representing the same path and overlapping HTTP methods are not allowed,
 * while two routes representing the same path and non-overlapping HTTP methods
 * can be used (and should typically resolve to different middleware).
 *
 * Internally, only those three properties are required. However, underlying
 * router implementations may allow or require additional information, such as
 * information defining how to generate a URL from the given route, qualifiers
 * for how segments of a route match, or even default values to use. These may
 * be provided after instantiation via the "options" property and related
 * setOptions() method.
 */
interface RouteInterface {
  public function getPath(): string;

  public function getName(): string;

  public function getMiddleware(): MiddlewareInterface;

  /**
   * @return null|Set<string> Returns null or set of allowed methods.
   */
  public function getAllowedMethods(): ?Container<string>;

  /**
   * Indicate whether the specified method is allowed by the route.
   *
   * @param string $method HTTP method to test.
   */
  public function allowsMethod(string $method): bool;

  public function setOptions(KeyedContainer<string, mixed> $options): void;

  public function getOptions(): KeyedContainer<string, mixed>;
}
