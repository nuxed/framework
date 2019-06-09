namespace Nuxed\Jwt\Token;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use namespace Nuxed\Util\{Base64, Json};
use namespace Nuxed\Jwt;
use namespace Nuxed\Jwt\Exception;
use namespace Nuxed\Jwt\Signer;
use namespace Facebook\TypeSpec;
use namespace Facebook\TypeAssert;

final class Builder implements Jwt\IBuilder {
  private dict<string, mixed> $headers = dict['alg' => null, 'typ' => 'JWT'];
  private dict<string, mixed> $claims = dict[];

  /**
   * {@inheritdoc}
   */
  public function permittedFor(string ...$audiences): Jwt\IBuilder {
    $configured = TypeSpec\vec(TypeSpec\string())->coerceType($this->claims[Claims::AUDIENCE] ?? vec[]);
    $toAppend = Vec\diff($audiences, $configured);
    $audiences = Vec\concat($configured, $toAppend);
    $this->claims[Claims::AUDIENCE] = $audiences;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function expiresAt(int $expiration): Jwt\IBuilder {
    $this->claims[Claims::EXPIRATION_TIME] = $expiration;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function identifiedBy(string $id): Jwt\IBuilder {
    $this->claims[Claims::ID] = $id;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function issuedAt(int $issuedAt): Jwt\IBuilder {
    $this->claims[Claims::ISSUED_AT] = $issuedAt;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function issuedBy(string $issuer): Jwt\IBuilder {
    $this->claims[Claims::ISSUER] = $issuer;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function canOnlyBeUsedAfter(int $notBefore): Jwt\IBuilder {
    $this->claims[Claims::NOT_BEFORE] = $notBefore;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function relatedTo(string $subject): Jwt\IBuilder {
    $this->claims[Claims::SUBJECT] = $subject;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function withHeader(string $name, mixed $value): Jwt\IBuilder {
    $this->headers[$name] = $value;
    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function withClaim(string $name, mixed $value): Jwt\IBuilder {
    if (C\contains(Claims::DATE_CLAIMS, $name)) {
      $value = TypeSpec\int()->coerceType($value);
    } elseif ($name === Claims::AUDIENCE) {
      $value = TypeSpec\vec(TypeSpec\string())->coerceType($value);
    } elseif (C\contains(Claims::ALL, $name)) {
      $value = TypeSpec\string()->coerceType($value);
    }

    $this->claims[$name] = $value;
    return $this;
  }

  private function encode(mixed $items): string {
    return Base64\url_encode(Json\encode($items));
  }

  /**
   * {@inheritdoc}
   */
  public function getToken(Jwt\ISigner $signer, Signer\Key $key): Plain {
    $headers = $this->headers;
    $headers['alg'] = $signer->getAlgorithmId();
    $encodedHeaders = $this->encode($headers);
    $encodedClaims = $this->encode($this->claims);
    $signature = $signer->sign($encodedHeaders.'.'.$encodedClaims, $key);
    $encodedSignature = Base64\url_encode($signature);

    return new Plain(
      new Headers($headers, $encodedHeaders),
      new Claims($this->claims, $encodedClaims),
      new Signature($signature, $encodedSignature),
    );
  }
}
