namespace Nuxed\Http\Message;

use namespace HH\Lib\Regex;
use namespace Nuxed\Contract\Http\Message;

trait RequestTrait {
  require implements Message\RequestInterface;

  protected string $method;

  protected ?string $requestTarget;

  protected Message\UriInterface $uri;

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

  public function getUri(): Message\UriInterface {
    return $this->uri;
  }

  public function withUri(Message\UriInterface $uri, bool $preserveHost = false): this {
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
