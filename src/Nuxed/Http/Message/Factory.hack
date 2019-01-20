namespace Nuxed\Http\Message;

use namespace Nuxed\Contract\Http\Message;
use function fopen;

class Factory
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
    dict<string, mixed> $serverParams = dict[],
  ): Message\ServerRequestInterface {
    return new ServerRequest($method, $uri, dict[], null, '1.1', $serverParams);
  }

  public function createServerRequestFromGlobals(
  ): Message\ServerRequestInterface {
    /* HH_IGNORE_ERROR[2050] */
    $server = (new __Private\ServerParametersMarshaler())->marshale($_SERVER);
    $headers = (new __Private\HeadersMarshaler())->marshal($server);
    /* HH_IGNORE_ERROR[2050] */
    $cookies = (new __Private\CookiesMarshaler())->marshal(
      $headers['cookie'] ?? vec[],
      $_COOKIE,
    );
    $uri = (new __Private\UriMarshaler())->marshal($server, $headers);
    /* HH_IGNORE_ERROR[2050] */
    $uploads = (new __Private\UploadedFilesMarshaler())->marshal($_FILES);
    $method = (new __Private\MethodMarshaler())->marshal($server);
    $body = dict[];
    /* HH_IGNORE_ERROR[2050] */
    foreach ($_POST as $key => $value) {
      $body[$key as string] = $value;
    }
    $query = dict[];
    /* HH_IGNORE_ERROR[2050] */
    foreach ($_GET as $key => $value) {
      $query[$key as string] = $value;
    }
    $protocolVersion =
      (new __Private\ProtocolVersionMarshaler())->marshal($server);

    $stream = new CachingStream(fopen('php://input', 'rb'));

    return (
      new ServerRequest(
        $method,
        $uri,
        $headers,
        $stream,
        $protocolVersion,
        $server,
      )
    )
      ->withCookieParams($cookies)
      ->withQueryParams($query)
      ->withParsedBody($body)
      ->withUploadedFiles($uploads);
  }

  public function createStream(string $content = ''): Message\StreamInterface {
    return __Private\create_stream_from_string($content);
  }

  public function createStreamFromFile(
    string $filename,
    string $mode = 'r',
  ): Message\StreamInterface {
    return new Stream(fopen($filename, $mode));
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
    return new Cookie($value);
  }

  public function createUri(string $uri = ''): Message\UriInterface {
    return new Uri($uri);
  }
}
