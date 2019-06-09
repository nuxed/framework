namespace Nuxed\Jwt\Signer;

use namespace Nuxed\Jwt;

<<__Sealed(Hmac\Sha256::class, Hmac\Sha384::class, Hmac\Sha512::class)>>
abstract class Hmac implements Jwt\ISigner {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  final public function sign(string $payload, Key $key): string {
    return \hash_hmac(
      $this->getAlgorithm(),
      $payload,
      $key->getContent(),
      true,
    );
  }

  /**
   * {@inheritdoc}
   */
  final public function verify(
    string $expected,
    string $payload,
    Key $key,
  ): bool {
    return \hash_equals($expected, $this->sign($payload, $key));
  }

  abstract public function getAlgorithm(): string;
}
