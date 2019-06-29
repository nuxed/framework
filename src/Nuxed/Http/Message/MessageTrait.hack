namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Regex, Str, Vec};

/**
 * Trait implementing functionality common to requests and responses.
 */
 <<__Sealed(RequestTrait::class, Response::class)>>
trait MessageTrait {

  /** @var dict<string, vec<string>> Map of all registered headers, as original name => Set of values */
  protected dict<string, vec<string>> $headers = dict[];

  /** @var dict<string, string> Map of lowercase header name => original name at registration */
  protected dict<string, string> $headerNames = dict[];

  protected string $protocol = '1.1';

  protected ?IStream $stream;

  public function messageClone(): void {
    $this->stream = null === $this->stream ? null : (clone $this->stream);
  }

  public function getProtocolVersion(): string {
    return $this->protocol;
  }

  public function withProtocolVersion(string $version): this {
    if ($this->protocol === $version) {
      return $this;
    }

    $new = clone $this;
    $new->protocol = $version;

    return $new;
  }

  public function getHeaders(): KeyedContainer<string, Container<string>> {
    return $this->headers;
  }

  public function hasHeader(string $header): bool {
    return C\contains_key($this->headerNames, Str\lowercase($header));
  }

  public function getHeader(string $header): Container<string> {
    $header = Str\lowercase($header);

    $header = $this->headerNames[$header] ?? null;

    if (null === $header) {
      return vec[];
    }

    return $this->headers[$header] ?? vec[];
  }

  public function getHeaderLine(string $header): string {
    return Str\join($this->getHeader($header), ', ');
  }

  public function withHeader(string $header, Container<string> $value): this {
    $value = $this->validateAndTrimHeader($header, $value);

    $normalized = Str\lowercase($header);

    $new = clone $this;

    if (C\contains_key($new->headerNames, $normalized)) {
      unset($new->headers[$new->headerNames[$normalized]]);
    }

    $new->headerNames[$normalized] = $header;
    $new->headers[$header] = vec($value);

    return $new;
  }

  public function withAddedHeader(
    string $header,
    Container<string> $value,
  ): this {
    if ('' === $header) {
      throw new Exception\InvalidArgumentException(
        'Header name must be an RFC 7230 compatible string.',
      );
    }

    $new = clone $this;
    $new->setHeaders(dict[
      $header => $value,
    ]);

    return $new;
  }

  public function withoutHeader(string $header): this {
    $normalized = Str\lowercase($header);

    if (!C\contains_key($this->headerNames, $normalized)) {
      return $this;
    }

    $header = $this->headerNames[$normalized];

    $new = clone $this;

    unset($new->headerNames[$normalized]);
    unset($new->headers[$header]);

    return $new;
  }

  public function getBody(): IStream {
    if (null === $this->stream) {
      $this->stream = stream('');
    }

    return $this->stream;
  }

  public function withBody(IStream $body): this {
    if ($body === $this->stream) {
      return $this;
    }

    $new = clone $this;
    $new->stream = $body;

    return $new;
  }

  protected function setHeaders(
    KeyedContainer<string, Container<string>> $headers,
  ): void {
    foreach ($headers as $header => $value) {
      $value = $this->validateAndTrimHeader($header, $value);

      $normalized = Str\lowercase($header);

      if (C\contains_key($this->headerNames, $normalized)) {
        $header = $this->headerNames[$normalized];
        $this->headers[$header] = Vec\unique(
          Vec\concat($this->headers[$header], $value),
        );
      } else {
        $this->headerNames[$normalized] = $header;
        $this->headers[$header] = vec($value);
      }
    }
  }

  /**
   * Make sure the header complies with RFC 7230.
   *
   * Header names must be a non-empty string consisting of token characters.
   *
   * Header values must be strings consisting of visible characters with all optional
   * leading and trailing whitespace stripped. This method will always strip such
   * optional whitespace. Note that the method does not allow folding whitespace within
   * the values as this was deprecated for almost all instances by the RFC.
   *
   * header-field = field-name ":" OWS field-value OWS
   * field-name   = 1*( "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." / "^"
   *              / "_" / "`" / "|" / "~" / %x30-39 / ( %x41-5A / %x61-7A ) )
   * OWS          = *( SP / HTAB )
   * field-value  = *( ( %x21-7E / %x80-FF ) [ 1*( SP / HTAB ) ( %x21-7E / %x80-FF ) ] )
   *
   * @see https://tools.ietf.org/html/rfc7230#section-3.2.4
   */
  protected function validateAndTrimHeader(
    string $header,
    Container<string> $values,
  ): Container<string> {
    if (!Regex\matches($header, re"@^[!#$%&'*+.^_`|~0-9A-Za-z-]+$@")) {
      throw new Exception\InvalidArgumentException(
        'Header name must be an RFC 7230 compatible string.',
      );
    }

    if (0 === C\count($values)) {
      throw new Exception\InvalidArgumentException(
        'Header values must be a vector of strings, empty vector given.',
      );
    }

    $retval = vec[];

    foreach ($values as $value) {

      if (!Regex\matches($value, re"@^[ \t\x21-\x7E\x80-\xFF]*$@")) {
        throw new Exception\InvalidArgumentException(
          'Header values must be RFC 7230 compatible strings.',
        );
      }

      $retval[] = Str\trim($value, " \t");
    }

    return $retval;
  }
}
