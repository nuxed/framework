namespace Nuxed\Http\Message;

use namespace Nuxed\Contract\Http\Message as Contract;

function cookie(
  string $value,
  ?\DateTimeInterface $expires = null,
  ?string $path = null,
  ?string $domain = null,
  bool $secure = false,
  bool $httpOnly = false,
  ?Contract\CookieSameSite $sameSite = null,
): Contract\CookieInterface {
  return new Cookie(
    $value,
    $expires,
    $path,
    $domain,
    $secure,
    $httpOnly,
    $sameSite,
  );
}

function request(
  string $method,
  Contract\UriInterface $uri,
  KeyedContainer<string, Container<string>> $headers = dict[],
  ?Contract\StreamInterface $body = null,
  string $version = '1.1',
): Contract\RequestInterface {
  return new Request($method, $uri, $headers, $body, $version);
}

function response(
  int $status = 200,
  KeyedContainer<string, Container<string>> $headers = dict[],
  ?Contract\StreamInterface $body = null,
  string $version = '1.1',
  ?string $reason = null,
): Contract\ResponseInterface {
  return new Response($status, $headers, $body, $version, $reason);
}

function stream(\Stringish $content): Contract\StreamInterface {
  $handle = \fopen('php://memory', 'wb+');
  \fwrite($handle, (string) $content);
  $stream = new Stream($handle);
  $stream->rewind();
  return $stream;
}

function uri(string $uri): Contract\UriInterface {
  return new Uri($uri);
}
