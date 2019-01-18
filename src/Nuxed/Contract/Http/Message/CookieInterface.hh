<?hh // strict

namespace Nuxed\Contract\Http\Message;

use type DateTime;

interface CookieInterface {
  /**
   * Return an instance with the specified expires date.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the domain option.
   */
  public function withValue(string $value): this;

  /**
   * Return an instance with the specified expires date.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the domain option.
   */
  public function withExpires(?DateTime $expires): this;

  /**
   * Return an instance with the specified path option.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the path option.
   *
   * A null value is equivalent to removing the path option.
   */
  public function withPath(?string $path): this;

  /**
   * Return an instance with the specified domain option.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance that contains the domain option.
   *
   * A null value is equivalent to removing the domain option.
   */
  public function withDomain(?string $domain): this;

  /**
   * Create a new instance with the provided secure option value.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance with the secure option set to the given value.
   *
   * @see isSecure();
   */
  public function withSecure(bool $secure = true): this;

  /**
   * Create a new instance with the provided http-only option value.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance with the http-only option set to the given value.
   *
   * @see isHttpOnly();
   */
  public function withHttpOnly(bool $httpOnly = true): this;

  /**
   * Create a new instance without the secure option.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance with the secure option set to false.
   *
   * @see isSecure();
   */
  public function withoutSecure(): this;

  /**
   * Create a new instance without the http-only option.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance with the http-only option set to false.
   *
   * @see isHttpOnly();
   */
  public function withoutHttpOnly(): this;

  /**
   * Create a new instance with the given same-site value.
   *
   * This method MUST retain the state of the current instance, and return
   * an instance with the given same-site value, if any.
   *
   * A null value is equivalent to removing the same-site option.
   *
   * @see getSameSite();
   */
  public function withSameSite(?CookieSameSite $sameSite): this;

  /**
   * Retrieve the value of the cookie.
   */
  public function getValue(): string;

  /**
   * Retrieve a DateTime instance representing the time the cookies expires.
   *
   * @return DataTime the time the cookie expires if specified, or null.
   */
  public function getExpires(): ?DateTime;

  /**
   * Retrieve the path on the server in which the cookie
   * will be available on.
   *
   * @return string the cookie path if specified, or null.
   */
  public function getPath(): ?string;

  /**
   * Retrieve the domain that the cookie is available to.
   *
   * @return string the cookie domain if specified, or null.
   */
  public function getDomain(): ?string;

  /**
   * Whether the cookie should only be transmitted over a secure HTTPS connection from the client.
   *
   * incase the secure option wasn't specified,
   * this method MUST return false.
   */
  public function isSecure(): bool;

  /**
   * Whether the cookie will be made accessible only through the HTTP protocol.
   *
   * incase the http-only option wasn't specified,
   * this method MUST return false.
   */
  public function isHttpOnly(): bool;

  /**
   * Retrieve the same-site attribute.
   *
   * @link https://tools.ietf.org/html/draft-west-first-party-cookies-07#section-3.1
   *
   * @return CookieSameSite the cookie same-site value if specified, or null.
   */
  public function getSameSite(): ?CookieSameSite;
}
