namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Math, Regex, Str, Vec};

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
   * Returns true if the response may safely be kept in a shared (surrogate) cache.
   *
   * Responses marked "private" with an explicit Cache-Control directive are
   * considered uncacheable.
   *
   * Responses with neither a freshness lifetime (Expires, max-age) nor cache
   * validator (Last-Modified, ETag) are considered uncacheable because there is
   * no way to tell when or how to remove them from the cache.
   *
   * Note that RFC 7231 and RFC 7234 possibly allow for a more permissive implementation,
   * for example "status codes that are defined as cacheable by default [...]
   * can be reused by a cache with heuristic expiration unless otherwise indicated"
   * (https://tools.ietf.org/html/rfc7231#section-6.1)
   */
  final public function isCacheable(): bool {
    if (
      !C\contains(vec[200, 203, 300, 301, 302, 404, 410], $this->statusCode)
    ) {
      return false;
    }

    $cacheControl = $this->getHeader('cache-control');

    if (C\contains($cacheControl, 'no-store')) {
      return false;
    }

    foreach ($cacheControl as $value) {
      if (Str\starts_with($value, 'private')) {
        return false;
      }
    }

    return $this->isValidateable() || $this->isFresh();
  }

  /**
   * Returns true if the response must be revalidated by caches.
   *
   * This method indicates that the response must not be served stale by a
   * cache in any circumstance without first revalidating with the origin.
   * When present, the TTL of the response should not be overridden to be
   * greater than the value provided by the origin.
   */
  final public function mustRevalidate(): bool {
    return $this->hasCacheControlDirective('must-revalidate') ||
      $this->hasCacheControlDirective('proxy-revalidate');
  }

  /**
   * Returns true if the response is "fresh".
   *
   * Fresh responses may be served from cache without any interaction with the
   * origin. A response is considered fresh when it includes a Cache-Control/max-age
   * indicator or Expires header and the calculated age is less than the freshness lifetime.
   */
  final public function isFresh(): bool {
    $ttl = $this->getTtl();
    return $ttl is null ? false : $ttl > 0;
  }

  /**
   * Returns true if the response includes headers that can be used to validate
   * the response with the origin server using a conditional GET request.
   */
  final public function isValidateable(): bool {
    return $this->hasHeader('Last-Modified') || $this->hasHeader('ETag');
  }

  /**
   * Returns the Date header as a DateTimeInterface instance.
   */
  final public function getDate(): ?\DateTimeInterface {
    return $this->getDateHeader('Date');
  }

  /**
   * Sets the Date header.
   */
  final public function withDate(\DateTimeInterface $date): this {
    return $this->withDateHeader('Date', $date);
  }

  /**
   * Returns the age of the response in seconds.
   */
  final public function getAge(): int {
    if ($this->hasHeader('Age')) {
      return (int)$this->getHeaderLine('Age');
    }

    if (!$this->hasHeader('Date')) {
      return 0;
    }

    return Math\max(vec[
      \time() - (int)($this->getDate() as nonnull->format('U')),
      0,
    ]) as int;
  }

  /**
   * Marks the response stale by setting the Age header to be equal to the maximum age of the response.
   */
  public function expire(): this {
    if ($this->isFresh()) {
      return $this->withoutHeader('Expires')
        ->withHeader('Age', vec[
          (string)($this->getMaxAge() as int),
        ]);
    }

    return $this;
  }

  /**
   * Returns the value of the Expires header as a DateTimeInterface instance.
   */
  final public function getExpires(): ?\DateTimeInterface {
    if (!$this->hasHeader('Expires')) {
      return null;
    }

    try {
      return $this->getDateHeader('Expires');
    } catch (\RuntimeException $e) {
      // according to RFC 2616 invalid date formats (e.g. "0" and "-1") must be treated as in the past
      return \DateTime::createFromFormat('U', (string)(\time() - 172800));
    }
  }

  /**
   * Sets the Expires HTTP header with a DateTime instance.
   */
  final public function withExpires(\DateTimeInterface $date): this {
    return $this->withDateHeader('Expires', $date);
  }

  /**
   * Removes the Expires HTTP header.
   */
  final public function withoutExpires(): this {
    return $this->withDateHeader('Expires', null);
  }

  /**
   * Returns the number of seconds after the time specified in the response's Date
   * header when the response should no longer be considered fresh.
   *
   * First, it checks for a s-maxage directive, then a max-age directive, and then it falls
   * back on an expires header. It returns null when no maximum age can be established.
   */
  final public function getMaxAge(): ?int {
    if (!$this->hasHeader('cache-control')) {
      return null;
    }

    if ($this->hasCacheControlDirective('s-maxage')) {
      return $this->getCacheControlDirective('s-maxage');
    }

    if ($this->hasCacheControlDirective('max-age')) {
      return $this->getCacheControlDirective('max-age');
    }

    $expires = $this->getExpires();
    if ($expires is nonnull) {
      $date = $this->getDate() as nonnull;
      return (int)$expires->format('U') - (int)$date->format('U');
    }

    return null;
  }

  /**
   * Sets the number of seconds after which the response should no longer be considered fresh.
   *
   * This methods sets the Cache-Control max-age directive.
   */
  final public function withMaxAge(int $value): this {
    return $this->withCacheControlDirective('max-age', $value);
  }

  /**
   * Sets the number of seconds after which the response should no longer be considered fresh by shared caches.
   *
   * This methods sets the Cache-Control s-maxage directive.
   */
  final public function withSharedMaxAge(int $value): this {
    return $this->withCacheControlDirective('public')
      ->withCacheControlDirective('s-maxage', $value);
  }

  /**
   * Returns true if the response is marked as "immutable".
   */
  final public function isImmutable(): bool {
    return $this->hasCacheControlDirective('immutable');
  }

  /**
   * Return the response with the "immutable" cache directive.
   */
  public function withImmutable(): this {
    return $this->withCacheControlDirective('immutable');
  }

  /**
   * Return the response without the "immutable" cache directive.
   */
  public function withoutImmutable(): this {
    return $this->withoutCacheControlDirective('immutable');
  }

  /**
   * Returns the response's time-to-live in seconds.
   *
   * It returns null when no freshness information is present in the response.
   *
   * When the responses TTL is <= 0, the response may not be served from cache without first
   * revalidating with the origin.
   */
  final public function getTtl(): ?int {
    $maxAge = $this->getMaxAge();

    return null !== $maxAge ? $maxAge - $this->getAge() : null;
  }

  /**
   * Sets the response's time-to-live for shared caches in seconds.
   *
   * This method adjusts the Cache-Control/s-maxage directive.
   */
  final public function withTtl(int $seconds): this {
    return $this->withSharedMaxAge($this->getAge() + $seconds);
  }

  /**
   * Sets the response's time-to-live for private/client caches in seconds.
   *
   * This method adjusts the Cache-Control/max-age directive.
   */
  public function setClientTtl(int $seconds): this {
    return $this->withMaxAge($this->getAge() + $seconds);
  }

  /**
   * Returns the Last-Modified HTTP header as a DateTime instance.
   *
   * @throws \RuntimeException When the HTTP header is not parseable
   *
   * @final
   */
  public function getLastModified(): ?\DateTimeInterface {
    return $this->getDateHeader('Last-Modified');
  }

  /**
   * Sets the Last-Modified HTTP header with a DateTime instance.
   */
  final public function withLastModified(\DateTimeInterface $date): this {
    return $this->withDateHeader('Last-Modified', $date);
  }

  /**
   * Remove the Last-Modified HTTP header.
   */
  final public function withoutLastModified(): this {
    return $this->withDateHeader('Last-Modified', null);
  }

  /**
   * Modifies the response so that it conforms to the rules defined for a 304 status code.
   *
   * This sets the status, removes the body, and discards any headers
   * that MUST NOT be included in 304 responses.
   *
   * @see http://tools.ietf.org/html/rfc2616#section-10.3.5
   */
  final public function withoutModifications(): this {
    $new = $this->withStatus(304, static::$phrases[304])
      ->withBody(stream(''));

    // remove headers that MUST NOT be included with 304 Not Modified responses
    foreach (
      vec[
        'Allow',
        'Content-Encoding',
        'Content-Language',
        'Content-Length',
        'Content-MD5',
        'Content-Type',
        'Last-Modified',
      ] as $header
    ) {
      $new = $instance->withoutHeader($header);
    }

    return $new;
  }

  /**
   * Returns true if the response includes a Vary header.
   */
  final public function hasVary(): bool {
    return $this->hasHeader('Vary');
  }

  /**
   * Returns an array of header names given in the Vary header.
   */
  final public function getVary(): Container<string> {
    if (!$this->hasVary()) {
      return vec[];
    }

    $vary = $this->getHeader('Vary');

    $ret = vec[];
    foreach ($vary as $item) {
      $ret = Vec\concat($ret, Regex\split($item, re"/[\s,]+/"));
    }

    return $ret;
  }

  /**
   * Sets the Vary header.
   *
   * @param bool         $replace Whether to replace the actual value or not (true by default)
   */
  final public function withVary(
    Container<string> $headers,
    bool $replace = true,
  ): this {
    if ($replace) {
      return $this->withHeader('Vary', $headers);
    } else {
      return $this->withAddedHeader('Vary', $headers);
    }
  }

  /**
   * Returns the literal value of the ETag HTTP header.
   */
  final public function getEtag(): ?string {
    if (!$this->hasHeader('ETag')) {
      return null;
    }

    return $this->getHeaderLine('ETag');
  }

  /**
   * Sets the ETag value.
   *
   * @param string  $etag The ETag unique identifier
   * @param bool    $weak Whether you want a weak ETag or not
   */
  final public function withEtag(string $etag, bool $weak = false): this {
    if (!Str\contains($etag, '"')) {
      $etag = '"'.$etag.'"';
    }

    return $this->withHeader('ETag', vec[($weak ? 'W/' : '').$etag]);
  }

  final public function withoutEtag(): this {
    return $this->withoutHeader('ETag');
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
