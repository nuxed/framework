namespace Nuxed\Http\Message;

use type Nuxed\Contract\Http\Message\RequestInterface;
use type Nuxed\Contract\Http\Message\UriInterface;
use function preg_match;

trait RequestTrait {
  require implements RequestInterface;

  protected string $method;

  protected ?string $requestTarget;

  protected UriInterface $uri;

  public function getRequestTarget(): string {
    if (null !== $this->requestTarget) {
      return $this->requestTarget;
    }

    if ('' === $target = $this->uri->getPath()) {
      $target = '/';
    }
    if ('' !== $this->uri->getQuery()) {
      $target .= '?'.$this->uri->getQuery();
    }

    return $target;
  }

  public function withRequestTarget(string $requestTarget): this {
    if (preg_match('#\s#', $requestTarget)) {
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

  public function getUri(): UriInterface {
    return $this->uri;
  }

  public function withUri(UriInterface $uri, bool $preserveHost = false): this {
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
