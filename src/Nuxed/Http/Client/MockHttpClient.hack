namespace Nuxed\Http\Client;

use namespace Nuxed\Http\Message;

final class MockHttpClient extends HttpClient {
  public function __construct(
    private (function(Message\Request): Awaitable<Message\Response>) $handler,
    HttpClientOptions $options = shape(),
  ) {
    parent::__construct($options);
  }

  <<__Override>>
  public function send(Message\Request $request): Awaitable<Message\Response> {
    $request = $this->prepare($request);
    $handler = $this->handler;
    return $handler($request);
  }
}
