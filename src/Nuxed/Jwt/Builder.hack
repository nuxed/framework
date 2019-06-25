namespace Nuxed\Jwt;

use namespace HH\Lib\{C, Vec};
use namespace Nuxed\Util\Json;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Crypto\Base64;

final class Builder implements IBuilder {
  private dict<string, mixed> $headers = dict['alg' => null, 'typ' => 'JWT'];
  private dict<string, mixed> $claims = dict[];

  /**
   * {@inheritdoc}
   */
  public function permittedFor(string ...$audiences): IBuilder {
    $configured = TypeSpec\vec(TypeSpec\string())->coerceType(
      $this->claims[Token\Claims::AUDIENCE] ?? vec[],
    );
    $toAppend = Vec\diff($audiences, $configured);
    $audiences = Vec\concat($configured, $toAppend);
    $this->claims[Token\Claims::AUDIENCE] = $audiences;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function expiresAt(int $expiration): IBuilder {
    $this->claims[Token\Claims::EXPIRATION_TIME] = $expiration;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function identifiedBy(string $id): IBuilder {
    $this->claims[Token\Claims::ID] = $id;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function issuedAt(int $issuedAt): IBuilder {
    $this->claims[Token\Claims::ISSUED_AT] = $issuedAt;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function issuedBy(string $issuer): IBuilder {
    $this->claims[Token\Claims::ISSUER] = $issuer;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function canOnlyBeUsedAfter(int $notBefore): IBuilder {
    $this->claims[Token\Claims::NOT_BEFORE] = $notBefore;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function relatedTo(string $subject): IBuilder {
    $this->claims[Token\Claims::SUBJECT] = $subject;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function withHeader(string $name, mixed $value): IBuilder {
    $this->headers[$name] = $value;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function withClaim(string $name, mixed $value): IBuilder {
    if (C\contains(Token\Claims::DATE_CLAIMS, $name)) {
      $value = TypeSpec\int()->coerceType($value);
    } else if ($name === Token\Claims::AUDIENCE) {
      $value = TypeSpec\vec(TypeSpec\string())->coerceType($value);
    } else if (C\contains(Token\Claims::ALL, $name)) {
      $value = TypeSpec\string()->coerceType($value);
    }

    $this->claims[$name] = $value;
    return $this;
  }

  private function encode(mixed $items): string {
    return Base64\UrlSafe\encode(Json\encode($items));
  }

  /**
   * {@inheritdoc}
   */
  public function getToken(ISigner $signer, Signer\Key $key): IToken {
    $headers = $this->headers;
    $headers['alg'] = $signer->getAlgorithmId();
    $encodedHeaders = $this->encode($headers);
    $encodedClaims = $this->encode($this->claims);
    $signature = $signer->sign($encodedHeaders.'.'.$encodedClaims, $key);
    $encodedSignature = Base64\UrlSafe\encode($signature);

    return new Token(
      new Token\Headers($headers, $encodedHeaders),
      new Token\Claims($this->claims, $encodedClaims),
      new Token\Signature($signature, $encodedSignature),
    );
  }
}
