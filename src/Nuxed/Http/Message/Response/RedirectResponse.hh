<?hh // strict

namespace Nuxed\Http\Message\Response;

use namespace Nuxed\Http\Message\__Private;
use type Nuxed\Contract\Http\Message\UriInterface;
use type Nuxed\Http\Message\Response;

/**
 * Produce a redirect response.
 */
class RedirectResponse extends Response {
  /**
   * Create a redirect response.
   *
   * Produces a redirect response with a Location header and the given status
   * (302 by default).
   *
   * Note: this method overwrites the `location` $headers value.
   *
   * @param int $status Integer status code for the redirect; 302 by default.
   * @param dict<string, vec<string>> $headers Map of headers to use at initialization.
   */
  public function __construct(
    UriInterface $uri,
    int $status = 302,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ) {
    $headers = dict($headers);
    $headers['location'] = vec[
      $uri->toString(),
    ];

    parent::__construct(
      $status,
      $headers,
      __Private\create_stream_from_string(''),
    );
  }
}
