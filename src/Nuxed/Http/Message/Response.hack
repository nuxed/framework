namespace Nuxed\Http\Message;

use namespace HH\Lib\C;

class Response {
  use MessageTrait;

  /** Map of standard HTTP status code/reason phrases */
  public static dict<int, string> $phrases = dict[
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-status',
    208 => 'Already Reported',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    306 => 'Switch Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Time-out',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Requested range not satisfiable',
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',
    422 => 'Unprocessable Entity',
    423 => 'Locked',
    424 => 'Failed Dependency',
    425 => 'Unordered Collection',
    426 => 'Upgrade Required',
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    451 => 'Unavailable For Legal Reasons',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Time-out',
    505 => 'HTTP Version not supported',
    506 => 'Variant Also Negotiates',
    507 => 'Insufficient Storage',
    508 => 'Loop Detected',
    511 => 'Network Authentication Required',
  ];

  protected dict<string, Cookie> $cookies = dict[];

  private string $reasonPhrase = '';

  private int $statusCode = 200;

  private ?string $charset = null;

  public function __construct(
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
    ?IStream $body = null,
    string $version = '1.1',
    ?string $reason = null,
  ) {
    $this->assertValidStatusCode($status);
    $this->statusCode = $status;
    $this->setHeaders($headers);

    if ($reason is null && C\contains_key(self::$phrases, $status)) {
      $this->reasonPhrase = self::$phrases[$status];
    } else {
      $this->reasonPhrase = $reason ?? '';
    }

    $this->protocol = $version;
    $this->stream = $body;
  }

  public function __clone(): void {
    $this->messageClone();
  }

  public function getStatusCode(): int {
    return $this->statusCode;
  }

  public function getReasonPhrase(): string {
    return $this->reasonPhrase;
  }

  public function withStatus(int $code, string $reasonPhrase = ''): this {
    $this->assertValidStatusCode($code);
    $new = clone $this;
    $new->statusCode = $code;

    if (
      '' === $reasonPhrase && C\contains_key(self::$phrases, $new->statusCode)
    ) {
      $reasonPhrase = self::$phrases[$new->statusCode];
    }

    $new->reasonPhrase = $reasonPhrase;

    return $new;
  }

  protected function assertValidStatusCode(int $code): void {
    if ($code < 100 || $code > 599) {
      throw new Exception\InvalidArgumentException(
        'Status code has to be an integer between 100 and 599',
      );
    }
  }

  public function getCookies(): KeyedContainer<string, Cookie> {
    return $this->cookies;
  }

  public function getCookie(string $name): ?Cookie {
    return $this->cookies[$name] ?? null;
  }

  public function withCookie(string $name, Cookie $cookie): this {
    $new = clone $this;
    $new->cookies[$name] = $cookie;
    return $new;
  }

  public function withoutCookie(string $name): this {
    if (!C\contains_key($this->cookies, $name)) {
      return $this;
    }

    $new = clone $this;
    unset($new->cookies[$name]);
    return $new;
  }

  /**
   * Sets the response charset.
   */
  public function withCharset(string $charset): this {
    $new = clone $this;
    $new->charset = $charset;

    return $new;
  }

  /**
   * Retrieves the response charset.
   */
  public function getCharset(): ?string {
    return $this->charset;
  }


  /**
   * Is response invalid?
   *
   * @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
   */
  final public function isInvalid(): bool {
    return $this->statusCode < 100 || $this->statusCode >= 600;
  }

  /**
   * Is response informative?
   */
  final public function isInformational(): bool {
    return $this->statusCode >= 100 && $this->statusCode < 200;
  }

  /**
   * Is response successful?
   */
  final public function isSuccessful(): bool {
    return $this->statusCode >= 200 && $this->statusCode < 300;
  }

  /**
   * Is the response a redirect?
   */
  final public function isRedirection(): bool {
    return $this->statusCode >= 300 && $this->statusCode < 400;
  }

  /**
   * Is there a client error?
   */
  final public function isClientError(): bool {
    return $this->statusCode >= 400 && $this->statusCode < 500;
  }

  /**
   * Was there a server side error?
   */
  final public function isServerError(): bool {
    return $this->statusCode >= 500 && $this->statusCode < 600;
  }

  /**
   * Is the response OK?
   */
  final public function isOk(): bool {
    return 200 === $this->statusCode;
  }

  /**
   * Is the response forbidden?
   */
  final public function isForbidden(): bool {
    return 403 === $this->statusCode;
  }

  /**
   * Is the response a not found error?
   */
  final public function isNotFound(): bool {
    return 404 === $this->statusCode;
  }

  /**
   * Is the response a redirect of some form?
   */
  final public function isRedirect(?string $location = null): bool {
    return C\contains(vec[201, 301, 302, 303, 307, 308], $this->statusCode) &&
      (null === $location || $location === $this->getHeaderLine('Location'));
  }

  /**
   * Is the response empty?
   */
  final public function isEmpty(): bool {
    return C\contains(vec[204, 304], $this->statusCode);
  }
}
