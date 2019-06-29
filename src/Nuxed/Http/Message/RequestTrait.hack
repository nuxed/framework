namespace Nuxed\Http\Message;

use namespace HH\Lib\Regex;

<<__Sealed(Request::class)>>
trait RequestTrait {
  use MessageTrait;

  protected string $method;

  protected ?string $requestTarget;

  protected Uri $uri;

  public function getRequestTarget(): string {
    if (null !== $this->requestTarget) {
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
    $new->method = $method;

    return $new;
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

    if (!$preserveHost || !$this->hasHeader('Host')) {
      $new->updateHostFromUri();
    }

    return $new;
  }

  abstract protected function updateHostFromUri(): void;
}
