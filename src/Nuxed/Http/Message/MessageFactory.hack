namespace Nuxed\Http\Message;

use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace Nuxed\Contract\Http\Message;
use namespace AzJezz\HttpNormalizer;


class MessageFactory
  implements
    Message\ResponseFactoryInterface,
    Message\RequestFactoryInterface,
    Message\ServerRequestFactoryInterface,
    Message\StreamFactoryInterface,
    Message\UploadedFileFactoryInterface,
    Message\CookieFactoryInterface,
    Message\UriFactoryInterface {
  public function createResponse(
    int $code = 200,
    string $reasonPhrase = '',
  ): Message\ResponseInterface {
    return (new Response())
      ->withStatus($code, $reasonPhrase);
  }

  public function createRequest(
    string $method,
    Message\UriInterface $uri,
  ): Message\RequestInterface {
    return new Request($method, $uri);
  }

  public function createServerRequest(
    string $method,
    Message\UriInterface $uri,
    KeyedContainer<string, mixed> $serverParams = dict[],
  ): Message\ServerRequestInterface {
    return new ServerRequest($method, $uri, dict[], null, '1.1', $serverParams);
  }

  public function createServerRequestFromGlobals(
  ): Message\ServerRequestInterface {
    /* HH_IGNORE_ERROR[2050] */
    $server = (new _Private\ServerParametersMarshaler())->marshale($_SERVER);
    $headers = (new _Private\HeadersMarshaler())->marshal($server);
    $uri = (new _Private\UriMarshaler())->marshal($server, $headers);
    $protocol = (new _Private\ProtocolVersionMarshaler())->marshal($server);

    $query = HttpNormalizer\parse($uri->getQuery());
    $method = Str\uppercase(($server['REQUEST_METHOD'] ?? 'GET') as string);
    $ct = $value ==> C\contains($headers['content-type'] ?? vec[], $value);

    if ('POST' === $method && (
      $ct('application/x-www-form-urlencoded') ||
      $ct('multipart/form-data')
    )) {
      /* HH_IGNORE_ERROR[2050] */
      $body = HttpNormalizer\normalize($_POST);
    } else {
      $body = null;
    }

    /* HH_IGNORE_ERROR[2050] */
    $uploads = HttpNormalizer\normalize_files($_FILES);
    /* HH_IGNORE_ERROR[2050] */
    $cookies = HttpNormalizer\normalize($_COOKIE);

    return new ServerRequest(
      $method, $uri, $headers, $this->createStreamFromFile('php://input', 'rb'), $protocol, $server
    )
      |> $$->withCookieParams(Dict\pull(
        $cookies,
        $value ==> $value[1],
        $value ==> $value[0],
      ))
      |> $$->withQueryParams(Dict\pull(
        $query,
        $value ==> $value[1],
        $value ==> $value[0],
      ))
      |> $body is nonnull ? $$->withParsedBody(Dict\pull(
        $body,
        $value ==> $value[1],
        $value ==> $value[0],
      )) : $$
      |> $$->withUploadedFiles(
        Dict\pull(Vec\map($uploads, ($value) ==> tuple(
          $value[0],
          $this->createUploadedFile(
            $this->createStreamFromFile($value[1]['tmp_name'], 'rb'),
            $value[1]['size'],
            Message\UploadedFileError::assert($value[1]['error']),
            $value[1]['name'] ?? null,
            $value[1]['type'] ?? null,
          )
        )),
        $value ==> $value[1],
        $value ==> $value[0],
        )
      );
  }

  public function createStream(string $content = ''): Message\StreamInterface {
    return stream($content);
  }

  public function createStreamFromFile(
    string $filename,
    string $mode = 'r',
  ): Message\StreamInterface {
    return new Stream(\fopen($filename, $mode));
  }

  public function createStreamFromResource(
    resource $resource,
  ): Message\StreamInterface {
    return new Stream($resource);
  }

  public function createUploadedFile(
    Message\StreamInterface $stream,
    ?int $size = null,
    Message\UploadedFileError $error = Message\UploadedFileError::ERROR_OK,
    ?string $clientFilename = null,
    ?string $clientMediaType = null,
  ): Message\UploadedFileInterface {
    return new UploadedFile(
      $stream,
      $size,
      $error,
      $clientFilename,
      $clientMediaType,
    );
  }

  public function createCookie(string $value): Message\CookieInterface {
    return cookie($value);
  }

  public function createUri(string $uri = ''): Message\UriInterface {
    return uri($uri);
  }
}
