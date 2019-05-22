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
   * @throws \Nuxed\Http\Client\Exception\IException If an error happens while processing the request.
   */
  public function send(Message\Request $request): Awaitable<Message\Response>;
}
