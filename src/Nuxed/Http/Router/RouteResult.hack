namespace Nuxed\Http\Router;

use type Nuxed\Contract\Http\Router\RouteResultInterface;
use type Nuxed\Contract\Http\Router\RouteInterface;

/**
 * Value object representing the results of routing.
 *
 * RouterInterface::match() is defined as returning a RouteResult instance,
 * which will contain the following state:
 *
 * - isSuccess()/isFailure() indicate whether routing succeeded or not.
 * - On success, it will contain:
 *   - the matched route name (typically the path)
 *   - the matched route middleware
 *   - any parameters matched by routing
 * - On failure:
 *   - isMethodFailure() further qualifies a routing failure to indicate that it
 *     was due to using an HTTP method not allowed for the given path.
 *   - If the failure was due to HTTP method negotiation, it will contain the
 *     list of allowed HTTP methods.
 *
 * RouteResult instances are consumed by the Application in the routing
 * middleware.
 */
final class RouteResult implements RouteResultInterface {
  private ?Container<string> $allowedMethods = null;

  private KeyedContainer<string, mixed> $matchedParams = dict[];

  private ?string $matchedRouteName = null;

  private ?RouteInterface $route = null;

  private bool $success = false;

  /**
   * Create an instance representing a route succes from the matching route.
   *
   * @param dict $params Parameters associated with the matched route, if any.
   */
  public static function fromRoute(
    RouteInterface $route,
    KeyedContainer<string, mixed> $params = dict[],
  ): this {
    $result = new static();
    $result->success = true;
    $result->route = $route;
    $result->matchedParams = $params;

    return $result;
  }

  /**
   * Create an instance representing a route failure.
   *
   * @param null|Container<string> $methods HTTP methods allowed for the current URI, if any.
   *     null is equivalent to allowing any HTTP method; empty Container means none.
   */
  public static function fromRouteFailure(?Container<string> $methods): this {
    $result = new static();
    $result->success = false;
    $result->allowedMethods = $methods;

    return $result;
  }

  /**
   * Does the result represent successful routing?
   */
  public function isSuccess(): bool {
    return $this->success;
  }

  /**
   * Retrieve the route that resulted in the route match.
   *
   * @return null|Route null if representing a routing failure;
   *     null if not created via fromRoute(); Route instance otherwise.
   */
  public function getMatchedRoute(): ?RouteInterface {
    return $this->isFailure() ? null : $this->route;
  }

  /**
   * Retrieve the matched route name, if possible.
   *
   * If this result represents a failure, return null; otherwise, return the
   * matched route name.
   */
  public function getMatchedRouteName(): ?string {
    if ($this->isFailure()) {
      return null;
    }

    if (null === $this->matchedRouteName && $this->route) {
      $this->matchedRouteName = $this->route->getName();
    }

    return $this->matchedRouteName;
  }

  /**
   * Returns the matched params.
   *
   * Guaranted to return a KeyedContainer<string, mixed>, even if it is simply empty.
   */
  public function getMatchedParams(): KeyedContainer<string, mixed> {
    return $this->matchedParams;
  }

  /**
   * Is this a routing failure result?
   */
  public function isFailure(): bool {
    return (!$this->success);
  }

  /**
   * Does the result represent failure to route due to HTTP method?
   */
  public function isMethodFailure(): bool {
    if ($this->isSuccess() || $this->allowedMethods === null) {
      return false;
    }

    return true;
  }

  /**
   * Retrieve the allowed methods for the route failure.
   *
   * @return null|Set<string> HTTP methods allowed
   */
  public function getAllowedMethods(): ?Container<string> {
    if ($this->isSuccess()) {
      $route = $this->getMatchedRoute();

      if (null !== $route) {
        return $route->getAllowedMethods();
      }

      return vec[];
    }

    return $this->allowedMethods;
  }
}
