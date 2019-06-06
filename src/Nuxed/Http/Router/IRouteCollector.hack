namespace Nuxed\Http\Router;

use namespace Nuxed\Http\Server;

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
interface IRouteCollector {
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
    Server\IMiddleware $middleware,
    ?Container<string> $methods = null,
    ?string $name = null,
  ): Route;

  /**
   * @param null|string $name The name of the route.
   */
  public function get(
    string $path,
    Server\IMiddleware $middleware,
    ?string $name = null,
  ): Route;

  /**
   * @param null|string $name The name of the route.
   */
  public function post(
    string $path,
    Server\IMiddleware $middleware,
    ?string $name = null,
  ): Route;

  /**
   * @param null|string $name The name of the route.
   */
  public function put(
    string $path,
    Server\IMiddleware $middleware,
    ?string $name = null,
  ): Route;

  /**
   * @param null|string $name The name of the route.
   */
  public function patch(
    string $path,
    Server\IMiddleware $middleware,
    ?string $name = null,
  ): Route;

  /**
   * @param null|string $name The name of the route.
   */
  public function delete(
    string $path,
    Server\IMiddleware $middleware,
    ?string $name = null,
  ): Route;

  /**
   * @param null|string $name The name of the route.
   */
  public function any(
    string $path,
    Server\IMiddleware $middleware,
    ?string $name = null,
  ): Route;

  /**
   * Add a route.
   *
   * This method adds a route against which the underlying implementation may
   * match.
   */
  public function addRoute(Route $route): void;

  /**
   * Retrieve all directly registered routes with the application.
   */
  public function getRoutes(): Container<Route>;
}
