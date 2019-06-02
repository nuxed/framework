namespace Nuxed\Http\Client;

use namespace Nuxed\Http\Message;

interface IHttpClient {
  /**
   * Sends a request and returns a response.
   *
   * @param Message\Request $request
   *
   * @return Awaitable<Message\Response>
   *
   * @throws Exception\IException If an error happens while processing the request.
   */
  public function send(Message\Request $request): Awaitable<Message\Response>;

  /**
   * Create and send an HTTP request.
   *
   * Use an absolute path to override the base path of the client, or a
   * relative path to append to the base path of the client. The URL can
   * contain the query string as well.
   */
  public function request(
    string $method,
    string $uri,
  ): Awaitable<Message\Response>;
}
