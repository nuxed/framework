namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Regex, Str};

<<__Sealed(Request::class)>>
trait RequestTrait {
  use MessageTrait;

  protected string $method;

  protected ?string $requestTarget;

  protected Uri $uri;

  public function getRequestTarget(): string {
    if ($this->requestTarget is nonnull) {
      return $this->requestTarget;
    }

    $target = $this->uri->getPath();
    if ('' === $target) {
      $target = '/';
    }

    $query = $this->uri->getQuery();
    if ('' !== $query) {
      $target .= '?'.$query;
    }

    $this->requestTarget = $target;
    return $target;
  }

  public function withRequestTarget(string $requestTarget): this {
    if (Regex\matches($requestTarget, re"#\s#")) {
      throw new Exception\InvalidArgumentException(
        'Invalid request target provided; cannot contain whitespace',
      );
    }

    $new = clone $this;
    $new->requestTarget = $requestTarget;

    return $new;
  }

  public function getMethod(): string {
    return $this->method;
  }

  public function withMethod(string $method): this {
    $new = clone $this;
    $new->method = Str\uppercase($method);

    return $new;
  }

  /**
   * Checks whether or not the method is safe.
   *
   * @see https://tools.ietf.org/html/rfc7231#section-4.2.1
   *
   * @return bool
   */
  public function isMethodSafe(): bool {
    return C\contains(
      vec['GET', 'HEAD', 'OPTIONS', 'TRACE'],
      $this->getMethod(),
    );
  }

  /**
   * Checks whether or not the method is idempotent.
   *
   * @return bool
   */
  public function isMethodIdempotent(): bool {
    return C\contains(
      vec['HEAD', 'GET', 'PUT', 'DELETE', 'TRACE', 'OPTIONS', 'PURGE'],
      $this->getMethod(),
    );
  }

  /**
   * Checks whether the method is cacheable or not.
   *
   * @see https://tools.ietf.org/html/rfc7231#section-4.2.3
   *
   * @return bool `true` for GET and HEAD, `false` otherwise
   */
  public function isMethodCacheable(): bool {
    return C\contains(vec['GET', 'HEAD'], $this->getMethod());
  }

  public function getUri(): Uri {
    return $this->uri;
  }

  public function withUri(Uri $uri, bool $preserveHost = false): this {
    if ($uri === $this->uri) {
      return $this;
    }

    $new = clone $this;
    $new->uri = $uri;
    $new->requestTarget = null;
    if (!$preserveHost || !$this->hasHeader('Host')) {
      $new->updateHostFromUri();
    }

    return $new;
  }

  abstract protected function updateHostFromUri(): void;
}
