namespace Nuxed\Jwt\Token;

use namespace HH\Lib\C;
use namespace Nuxed\Util;
use namespace Facebook\TypeSpec;

/**
 * Defines the list of claims that are registered in the IANA "JSON Web Token Claims" registry
 *
 * @see https://tools.ietf.org/html/rfc7519#section-4.1
 */
final class Claims {
  use Util\StringableTrait;

  const type Type = shape(
    ?self::AUDIENCE => Container<string>,
    ?self::EXPIRATION_TIME => int,
    ?self::ID => string,
    ?self::ISSUED_AT => int,
    ?self::ISSUER => string,
    ?self::NOT_BEFORE => int,
    ?self::SUBJECT => string,
    ...
  );

  const vec<string> ALL = vec[
    self::AUDIENCE,
    self::EXPIRATION_TIME,
    self::ID,
    self::ISSUED_AT,
    self::ISSUER,
    self::NOT_BEFORE,
    self::SUBJECT,
  ];

  const vec<string> DATE_CLAIMS = vec[
    self::ISSUED_AT,
    self::NOT_BEFORE,
    self::EXPIRATION_TIME,
  ];

  /**
   * Identifies the recipients that the JWT is intended for
   *
   * @see https://tools.ietf.org/html/rfc7519#section-4.1.3
   */
  const string AUDIENCE = 'aud';

  /**
   * Identifies the expiration time on or after which the JWT MUST NOT be accepted for processing
   *
   * @see https://tools.ietf.org/html/rfc7519#section-4.1.4
   */
  const string EXPIRATION_TIME = 'exp';

  /**
   * Provides a unique identifier for the JWT
   *
   * @see https://tools.ietf.org/html/rfc7519#section-4.1.7
   */
  const string ID = 'jti';

  /**
   * Identifies the time at which the JWT was issued
   *
   * @see https://tools.ietf.org/html/rfc7519#section-4.1.6
   */
  const string ISSUED_AT = 'iat';

  /**
   * Identifies the principal that issued the JWT
   *
   * @see https://tools.ietf.org/html/rfc7519#section-4.1.1
   */
  const string ISSUER = 'iss';

  /**
   * Identifies the time before which the JWT MUST NOT be accepted for processing
   *
   * https://tools.ietf.org/html/rfc7519#section-4.1.5
   */
  const string NOT_BEFORE = 'nbf';

  /**
   * Identifies the principal that is the subject of the JWT.
   *
   * https://tools.ietf.org/html/rfc7519#section-4.1.2
   */
  const string SUBJECT = 'sub';

  public function __construct(
    private KeyedContainer<string, mixed> $data,
    private string $encoded,
  ) {}

  public function get(string $name, mixed $default = null): dynamic {
    return $this->data[$name] ?? $default;
  }

  public function contains(string $name): bool {
    return C\contains_key($this->data, $name);
  }

  public function getAudience(): ?Container<string> {
    return TypeSpec\nullable(TypeSpec\vec(TypeSpec\string()))
      ->coerceType($this->get(self::AUDIENCE, null));
  }

  public function getExpirationTime(): ?int {
    return TypeSpec\nullable(TypeSpec\int())
      ->coerceType($this->get(self::EXPIRATION_TIME, null));
  }

  public function getId(): ?string {
    return TypeSpec\nullable(TypeSpec\string())
      ->coerceType($this->get(self::ID, null));
  }

  public function getIssuedAt(): ?int {
    return TypeSpec\nullable(TypeSpec\int())
      ->coerceType($this->get(self::ISSUED_AT, null));
  }

  public function getIssuer(): ?string {
    return TypeSpec\nullable(TypeSpec\string())
      ->coerceType($this->get(self::ISSUER, null));
  }

  public function getNotBefore(): ?int {
    return TypeSpec\nullable(TypeSpec\int())
      ->coerceType($this->get(self::NOT_BEFORE, null));
  }

  public function getSubject(): ?string {
    return TypeSpec\nullable(TypeSpec\string())
      ->coerceType($this->get(self::SUBJECT, null));
  }

  public function toString(): string {
    return $this->encoded;
  }
}
