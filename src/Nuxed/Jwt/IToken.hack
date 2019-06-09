namespace Nuxed\Jwt;

use namespace Nuxed\Util;

interface IToken extends Util\Stringable {
  /**
   * Returns the token headers
   */
  public function getHeaders(): Token\Headers;

  /**
   * Returns the token claims
   */
  public function getClaims(): Token\Claims;

  /**
   * Returns the token signature
   */
  public function getSignature(): Token\Signature;

  /**
   * Returns the token payload
   */
  public function getPayload(): string;

  /**
   * Returns if the token is allowed to be used by the audience
   */
  public function isPermittedFor(string $audience): bool;

  /**
   * Returns if the token has the given id
   */
  public function isIdentifiedBy(string $id): bool;

  /**
   * Returns if the token has the given subject
   */
  public function isRelatedTo(string $subject): bool;

  /**
   * Returns if the token was issued by any of given issuers
   */
  public function hasBeenIssuedBy(string ...$issuers): bool;

  /**
   * Returns if the token was issued before of given time
   *
   * Returns NULL if the token doesn't contain the `iat` claim.
   */
  public function hasBeenIssuedBefore(int $now): ?bool;

  /**
   * Returns if the token minimum time is before than given time
   *
   * Returns NULL if the token doesn't contain the `nbf` claim.
   */
  public function isMinimumTimeBefore(int $now): ?bool;

  /**
   * Returns if the token is expired
   */
  public function isExpired(int $now): bool;

  /**
   * Returns an encoded representation of the token
   */
  public function toString(): string;
}
