namespace Nuxed\Http\Client;

use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace Nuxed\Http\Message;
use namespace Facebook\TypeSpec;
use namespace Facebook\TypeAssert;

abstract class HttpClient implements IHttpClient {
  const HttpClientOptions DEFAULT_OPTIONS = shape(
    'headers' => dict[],
    'max_redirects' => 20,
    'bindto' => '0',
    'verify_peer' => true,
    'verify_host' => true,
    'capture_peer_cert_chain' => false,
  );

  public function __construct(protected HttpClientOptions $options = shape()) {
    $this->setOptions($options);
  }

  public static function create(
    HttpClientOptions $options = shape(),
  ): HttpClient {
    return new CurlHttpClient($options);
  }


  /**
   * Create and send an HTTP request.
   *
   * Use an absolute path to override the base path of the client, or a
   * relative path to append to the base path of the client. The URL can
   * contain the query string as well.
   */
  public function request(
    string $method,
    string $uri,
  ): Awaitable<Message\Response> {
    return $this->send(Message\request($method, Message\uri($uri)));
  }

  final protected function prepare(Message\Request $request): Message\Request {
    $uri = $request->getUri();
    list($user, $password) = $uri->getUserInfo();
    if (!$request->hasHeader('authorization')) {
      if ('' !== $user) {
        $request = $request->withAddedHeader('authorization', vec[
          Str\format(
            'Basic %s',
            \base64_encode($user.($password is null ? '' : ':'.$password)),
          ),
        ]);
      } else {
        $token = Shapes::idx($this->options, 'auth_bearer', null);
        if ($token is nonnull) {
          $request = $request->withAddedHeader('authorization', vec[
            Str\format('Bearer %s', $token),
          ]);
        }
      }
    }
    $uri = $uri->withUserInfo('', null);

    $headers = Shapes::idx($this->options, 'headers', dict[]);
    foreach ($headers as $name => $value) {
      if (!$request->hasHeader($name)) {
        $request = $request->withHeader($name, $value);
      } else {
        $request = $request->withAddedHeader($name, $value);
      }
    }

    $protocol = $this->options['http_version'] ??
      $request->getProtocolVersion();
    if ($protocol !== '1.1') {
      $request = $request->withProtocolVersion($protocol);
    }
  
    $body = $request->getBody();
    if ($body->isSeekable()) {
      $body->rewind();
    }

    return $request->withUri($uri);
  }

  public function setOptions(HttpClientOptions $options): this {
    $current = Shapes::toDict($this->options);
    $new = Shapes::toDict($options);
    $default = Shapes::toDict(static::DEFAULT_OPTIONS);
    $strSpec = TypeSpec\string();
    $spec = TypeSpec\dict($strSpec, $strSpec);
    $new['resolve'] = Dict\merge(
      $spec->assertType($current['resolve'] ?? dict[]),
      $spec->assertType($new['resolve'] ?? dict[]),
    );
    $spec = TypeSpec\vec($strSpec);
    $new['ciphers'] = Dict\merge(
      $spec->assertType($current['ciphers'] ?? vec[]),
      $spec->assertType($new['ciphers'] ?? vec[]),
    );
    $spec = TypeSpec\dict($strSpec, $spec);
    $new['headers'] = Dict\merge(
      $spec->assertType($current['headers'] ?? dict[]),
      $spec->assertType($new['headers'] ?? dict[]),
    );
    $new['peer_fingerprint'] = Dict\merge(
      $spec->assertType($current['peer_fingerprint'] ?? dict[]),
      $spec->assertType($new['peer_fingerprint'] ?? dict[]),
    );
    $options = Dict\merge($default, $current, $new);
    $this->options = TypeAssert\matches_type_structure(
      _Private\Structure::HttpClientOptions(),
      $options,
    );
    return $this;
  }
}
