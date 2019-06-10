namespace Nuxed\Jwt\Signer;

<<__Sealed(Rsa\Sha256::class, Rsa\Sha384::class, Rsa\Sha512::class)>>
abstract class Rsa extends OpenSSL {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  final public function sign(string $payload, Key $key): string {
    return $this->createSignature(
      $key->getContent(),
      $key->getPassphrase(),
      $payload,
    );
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  final public function verify(
    string $expected,
    string $payload,
    Key $key,
  ): bool {
    return $this->verifySignature($expected, $payload, $key->getContent());
  }

  /**
   * {@inheritdoc}
   */ <<__Override>>
 final public function getKeyType(): int {
    return \OPENSSL_KEYTYPE_RSA;
  }
}
