namespace Nuxed\Http\Router\Generator;

use namespace Nuxed\Http\Message;

interface IUriGenerator {
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
  ): Message\Uri;
}
