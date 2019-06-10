namespace Nuxed\Jwt;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace Nuxed\Util;
use namespace Nuxed\Jwt;

final class Token implements Jwt\IToken {
  use Util\StringableTrait;

  public function __construct(
    private Token\Headers $headers,
    private Token\Claims $claims,
    private Token\Signature $signature,
  ) {}

  /**
   * {@inheritdoc}
   */
  public function getHeaders(): Token\Headers {
    return $this->headers;
  }
  /**
   * {@inheritdoc}
   */
  public function getClaims(): Token\Claims {
    return $this->claims;
  }

  /**
   * {@inheritdoc}
   */
  public function getSignature(): Token\Signature {
    return $this->signature;
  }

  /**
   * {@inheritdoc}
   */
  public function getPayload(): string {
    return $this->headers->toString().'.'.$this->claims->toString();
  }

  /**
   * {@inheritdoc}
   */
  public function isPermittedFor(string $audience): bool {
    return C\contains($this->claims->getAudience() ?? vec[], $audience);
  }

  /**
   * {@inheritdoc}
   */
  public function isIdentifiedBy(string $id): bool {
    return $this->claims->getId() === $id;
  }

  /**
   * {@inheritdoc}
   */
  public function isRelatedTo(string $subject): bool {
    return $this->claims->getSubject() === $subject;
  }

  /**
   * {@inheritdoc}
   */
  public function hasBeenIssuedBy(string ...$issuers): bool {
    return C\contains($issuers, $this->claims->getIssuer());
  }

  /**
   * {@inheritdoc}
   */
  public function hasBeenIssuedBefore(int $now): ?bool {
    $tokenIssueTime = $this->claims->getIssuedAt();
    if ($tokenIssueTime is null) {
      return null;
    }
    return $now >= $tokenIssueTime;
  }

  /**
   * {@inheritdoc}
   */
  public function isMinimumTimeBefore(int $now): ?bool {
    $notBefore = $this->claims->getNotBefore();
    if ($notBefore is null) {
      return null;
    }
    return $now >= $notBefore;
  }

  /**
   * {@inheritdoc}
   */
  public function isExpired(int $now): bool {
    $tokenExpirationTime = $this->claims->getExpirationTime();
    if ($tokenExpirationTime is null) {
      return false;
    }

    return $now > $tokenExpirationTime;
  }

  /**
   * {@inheritdoc}
   */
  public function toString(): string {
    return Str\join(
      vec[
        $this->headers->toString(),
        $this->claims->toString(),
        $this->signature->toString(),
      ],
      '.',
    );
  }
}
