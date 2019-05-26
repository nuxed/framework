namespace Nuxed\Http\Client;

use namespace Nuxed\Http\Message;

final class MockHttpClient implements IHttpClient {
  public function __construct(
    private (function(Message\Request): Awaitable<Message\Response>) $client,
  ) {}

  public function send(Message\Request $request): Awaitable<Message\Response> {
    $client = $this->client;
    return $client($request);
  }
}
