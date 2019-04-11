namespace Nuxed\Http\Message;

use namespace HH\Lib\C;
use namespace Nuxed\Util;
use namespace Nuxed\Contract\Http\Message;

class Request implements Message\RequestInterface {
  use MessageTrait;
  use RequestTrait;

  public function __construct(
    string $method,
    Message\UriInterface $uri,
    KeyedContainer<string, Container<string>> $headers = dict[],
    ?Message\StreamInterface $body = null,
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

    $this->headers = Util\Dict::union(dict[$header => vec[$host]], $this->headers);
  }

  public function __clone(): void {
    $this->messageClone();
  }
}
