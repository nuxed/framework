namespace Nuxed\Contract\Http\Message;

interface RequestFactoryInterface {
  /**
   * Create a new request.
   *
   * @param string $method The HTTP method associated with the request.
   * @param UriInterface $uri The URI associated with the request.
   *
   * @return RequestInterface
   */
  public function createRequest(
    string $method,
    UriInterface $uri,
  ): RequestInterface;
}
