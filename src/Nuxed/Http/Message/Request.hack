namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Dict};

class Request {
  use RequestTrait;

  public function __construct(
    string $method,
    Uri $uri,
    KeyedContainer<string, Container<string>> $headers = dict[],
    ?IStream $body = null,
    string $version = '1.1',
  ) {
    $this->method = $method;
    $this->uri = $uri;
    $this->setHeaders($headers);
    $this->protocol = $version;

    if (!$this->hasHeader('Host')) {
      $this->updateHostFromUri();
    }

    if (null !== $body) {
      $this->stream = $body;
    }
  }

  <<__Override>>
  protected function updateHostFromUri(): void {
    $host = $this->uri->getHost();
    if ('' === $host) {
      return;
    }

    $port = $this->uri->getPort();

    if (null !== $port) {
      $host .= ':'.((string)$port);
    }

    if (C\contains_key($this->headerNames, 'host')) {
      $header = $this->headerNames['host'];
    } else {
      $header = 'Host';
      $this->headerNames['host'] = 'Host';
    }

    if (C\contains_key($this->headers, $header)) {
      unset($this->headers[$header]);
    }

    $this->headers = Dict\merge(dict[$header => vec[$host]], $this->headers);
  }

  public function __clone(): void {
    $this->messageClone();
  }
}
