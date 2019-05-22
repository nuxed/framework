namespace Nuxed\Http\Message;

function cookie(
  string $value,
  ?\DateTimeInterface $expires = null,
  ?string $path = null,
  ?string $domain = null,
  bool $secure = false,
  bool $httpOnly = false,
  ?CookieSameSite $sameSite = null,
): Cookie {
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
  Uri $uri,
  KeyedContainer<string, Container<string>> $headers = dict[],
  ?IStream $body = null,
  string $version = '1.1',
): Request {
  return new Request($method, $uri, $headers, $body, $version);
}

function response(
  int $status = 200,
  KeyedContainer<string, Container<string>> $headers = dict[],
  ?IStream $body = null,
  string $version = '1.1',
  ?string $reason = null,
): Response {
  return new Response($status, $headers, $body, $version, $reason);
}

function stream(\Stringish $content): IStream {
  $handle = \fopen('php://memory', 'wb+');
  \fwrite($handle, (string)$content);
  $stream = new Stream($handle);
  $stream->rewind();
  return $stream;
}

function uri(string $uri): Uri {
  return new Uri($uri);
}
