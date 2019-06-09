namespace Nuxed\Jwt;

interface IBuilder {
  /**
   * Appends new items to audience
   */
  public function permittedFor(string ...$audiences): IBuilder;

  /**
   * Configures the expiration time
   */
  public function expiresAt(int $expiration): IBuilder;

  /**
   * Configures the token id
   */
  public function identifiedBy(string $id): IBuilder;

  /**
   * Configures the time that the token was issued
   */
  public function issuedAt(int $issuedAt): IBuilder;

  /**
   * Configures the issuer
   */
  public function issuedBy(string $issuer): IBuilder;

  /**
   * Configures the time before which the token cannot be accepted
   */
  public function canOnlyBeUsedAfter(int $notBefore): IBuilder;

  /**
   * Configures the subject
   */
  public function relatedTo(string $subject): IBuilder;

  /**
   * Configures a header item
   *
   * @param mixed $value
   */
  public function withHeader(string $name, mixed $value): IBuilder;

  /**
   * Configures a claim item
   *
   * @param mixed $value
   *
   * @throws InvalidArgumentException When trying to set a registered claim.
   */
  public function withClaim(string $name, mixed $value): IBuilder;

  /**
   * Returns a signed token to be used
   */
  public function getToken(ISigner $signer, Signer\Key $key): IToken;
}
