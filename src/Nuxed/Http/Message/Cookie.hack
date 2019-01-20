namespace Nuxed\Http\Message;

use type Nuxed\Contract\Http\Message\CookieInterface;
use type Nuxed\Contract\Http\Message\CookieSameSite;
use type DateTime;

class Cookie implements CookieInterface {
  public function __construct(
    protected string $value,
    protected ?DateTime $expires = null,
    protected ?string $path = null,
    protected ?string $domain = null,
    protected bool $secure = false,
    protected bool $httpOnly = false,
    protected ?CookieSameSite $sameSite = null,
  ) {}

  public function withValue(string $value): this {
    $new = clone $this;
    $new->value = $value;

    return $new;
  }

  public function withExpires(?DateTime $expires): this {
    $new = clone $this;
    $new->expires = $expires;

    return $new;
  }

  public function withPath(?string $path): this {
    $new = clone $this;
    $new->path = $path;

    return $new;
  }

  public function withDomain(?string $domain): this {
    $new = clone $this;
    $new->domain = $domain;

    return $new;
  }

  public function withSecure(bool $secure = true): this {
    $new = clone $this;
    $new->secure = $secure;

    return $new;
  }

  public function withHttpOnly(bool $httpOnly = true): this {
    $new = clone $this;
    $new->httpOnly = $httpOnly;

    return $new;
  }

  public function withoutSecure(): this {
    $new = clone $this;
    $new->secure = false;

    return $new;
  }

  public function withoutHttpOnly(): this {
    $new = clone $this;
    $new->httpOnly = false;

    return $new;
  }

  public function withSameSite(?CookieSameSite $sameSite): this {
    $new = clone $this;
    $new->sameSite = $sameSite;

    return $new;
  }

  public function getValue(): string {
    return $this->value;
  }

  public function getExpires(): ?DateTime {
    return $this->expires;
  }

  public function getPath(): ?string {
    return $this->path;
  }

  public function getDomain(): ?string {
    return $this->domain;
  }

  public function isSecure(): bool {
    return $this->secure;
  }

  public function isHttpOnly(): bool {
    return $this->httpOnly;
  }

  public function getSameSite(): ?CookieSameSite {
    return $this->sameSite;
  }
}
