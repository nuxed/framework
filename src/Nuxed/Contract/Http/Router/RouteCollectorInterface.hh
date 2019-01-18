<?hh // strict

namespace Nuxed\Contract\Http\Router;

use type Nuxed\Contract\Http\Server\MiddlewareInterface;

/**
 * Aggregate routes for the router.
 *
 * This class provides * methods for creating path+HTTP method-based routes and
 * injecting them into the router:
 *
 * - get
 * - post
 * - put
 * - patch
 * - delete
 * - any
 *
 * A general `route()` method allows specifying multiple request methods and/or
 * arbitrary request methods when creating a path-based route.
 *
 * Internally, the implementation should performs some checks for duplicate routes when
 * attaching via one of the exposed methods, and will raise an exception when a
 * collision occurs.
 */
interface RouteCollectorInterface {
  /**
   * Add a route for the route middleware to match.
   *
   * Accepts a combination of a path and middleware, and optionally the HTTP methods allowed.
   *
   * @param null|Container<string> $methods HTTP method to accept; null indicates any.
   * @param null|string $name The name of the route.
   */
  public function route(
    string $path,
    MiddlewareInterface $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): RouteInterface;

  /**
   * @param null|string $name The name of the route.
   */
  public function get(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface;

  /**
   * @param null|string $name The name of the route.
   */
  public function post(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface;

  /**
   * @param null|string $name The name of the route.
   */
  public function put(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface;

  /**
   * @param null|string $name The name of the route.
   */
  public function patch(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface;

  /**
   * @param null|string $name The name of the route.
   */
  public function delete(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface;

  /**
   * @param null|string $name The name of the route.
   */
  public function any(
    string $path,
    MiddlewareInterface $middleware,
    ?string $name = null,
  ): RouteInterface;

  /**
   * Retrieve all directly registered routes with the application.
   */
  public function getRoutes(): Container<RouteInterface>;
}
