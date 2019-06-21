namespace Nuxed\Http\Client;

use namespace Nuxed\Http\Message;

final class MockHttpClient extends HttpClient {
  public function __construct(
    private (function(Message\Request): Awaitable<Message\Response>) $handler,
    HttpClientOptions $options = shape(),
  ) {
    parent::__construct($options);
  }

  /**
   * Process the request and returns a response.
   *
   * @throws Exception\IException If an error happens while processing the request.
   */
  <<__Override>>
  public function process(
    Message\Request $request,
  ): Awaitable<Message\Response> {
    return ($this->handler)($request);
  }
}
