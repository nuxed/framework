namespace Nuxed\Contract\Http\Router;

use type Nuxed\Contract\Http\Message\RequestInterface;
use type Nuxed\Contract\Http\Message\UriInterface;

interface RouterInterface {
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
   * The method MUST raise Exception\RuntimeException if called after either `match()`
   * or `generateUri()` have already been called, to ensure integrity of the
   * router between invocations of either of those methods.
   *
   * @throws Exception\RuntimeException when called after match() or
   *     generateUri() have been called.
   */
  public function addRoute(RouteInterface $route): void;

  /**
   * Match a request against the known routes.
   *
   * Implementations will aggregate required information from the provided
   * request instance, and pass them to the underlying router implementation;
   * when done, they will then marshal a `RouteResult` instance indicating
   * the results of the matching operation and return it to the caller.
   */
  public function match(RequestInterface $request): RouteResultInterface;

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
  ): UriInterface;
}
