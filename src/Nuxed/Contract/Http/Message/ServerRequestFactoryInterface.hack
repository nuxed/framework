namespace Nuxed\Contract\Http\Message;

interface ServerRequestFactoryInterface {
  /**
   * Create a new server request.
   *
   * Note that server-params are taken precisely as given - no parsing/processing
   * of the given values is performed, and, in particular, no attempt is made to
   * determine the HTTP method or URI, which must be provided explicitly.
   *
   * @param string $method The HTTP method associated with the request.
   * @param UriInterface $uri The URI associated with the request.
   * @param Map<string, mixed> $serverParams Map of SAPI parameters with which to seed
   *     the generated request instance.
   *
   * @return ServerRequestInterface
   */
  public function createServerRequest(
    string $method,
    UriInterface $uri,
    dict<string, mixed> $serverParams = dict[],
  ): ServerRequestInterface;
}
