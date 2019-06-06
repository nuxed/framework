namespace Nuxed\Http\Router\Matcher;

use namespace Nuxed\Http\Router;
use namespace Nuxed\Http\Message;

interface IRequestMatcher {
  /**
   * Match a request against the known routes.
   *
   * Implementations will aggregate required information from the provided
   * request instance, and pass them to the underlying router implementation;
   * when done, they will then marshal a `Router\RouteResult` instance indicating
   * the results of the matching operation and return it to the caller.
   */
  public function match(Message\Request $request): Router\RouteResult;
}
