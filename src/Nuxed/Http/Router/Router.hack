namespace Nuxed\Http\Router;

use namespace Nuxed\Http\Message;

final class Router implements IRouter {
  public function __construct(
    private Matcher\IRequestMatcher $matcher,
    private Generator\IUriGenerator $generator,
  ) {}

  /**
   * Match a request against the known routes.
   */
  public function match(Message\Request $request): RouteResult {
    return $this->matcher->match($request);
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
  public function generate(
    string $route,
    KeyedContainer<string, mixed> $substitutions = dict[],
  ): Message\Uri {
    return $this->generator->generate($route, $substitutions);
  }
}
