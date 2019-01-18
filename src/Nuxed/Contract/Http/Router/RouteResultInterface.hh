<?hh // strict

namespace Nuxed\Contract\Http\Router;

interface RouteResultInterface {
  /**
  * Does the result represent successful routing?
  */
  public function isSuccess(): bool;

  /**
   * Retrieve the route that resulted in the route match.
   *
   * @return null|RouteInterface null if representing a routing failure;
   *     null if not created via fromRoute(); Route instance otherwise.
   */
  public function getMatchedRoute(): ?RouteInterface;

  /**
   * Retrieve the matched route name, if possible.
   *
   * If this result represents a failure, return null; otherwise, return the
   * matched route name.
   */
  public function getMatchedRouteName(): ?string;

  /**
   * Returns the matched params.
   *
   * Guaranted to return a KeyedContainer<string, mixed>, even if it is simply empty.
   */
  public function getMatchedParams(): KeyedContainer<string, mixed>;

  /**
   * Is this a routing failure result?
   */
  public function isFailure(): bool;

  /**
   * Does the result represent failure to route due to HTTP method?
   */
  public function isMethodFailure(): bool;

  /**
   * Retrieve the allowed methods for the route failure.
   */
  public function getAllowedMethods(): ?Container<string>;
}
