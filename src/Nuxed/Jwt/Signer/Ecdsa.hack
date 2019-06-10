namespace Nuxed\Jwt\Signer;

<<
  __ConsistentConstruct,
  __Sealed(Ecdsa\Sha256::class, Ecdsa\Sha384::class, Ecdsa\Sha512::class)
>>
abstract class Ecdsa extends OpenSSL {
  public function __construct(private Ecdsa\ISignatureConverter $converter) {}

  public static function create(): Ecdsa {
    return new static(new Ecdsa\MultibyteStringConverter());
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  final public function sign(string $payload, Key $key): string {
    return $this->converter->fromAsn1(
      $this->createSignature(
        $key->getContent(),
        $key->getPassphrase(),
        $payload,
      ),
      $this->getKeyLength(),
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
    return $this->verifySignature(
      $this->converter->toAsn1($expected, $this->getKeyLength()),
      $payload,
      $key->getContent(),
    );
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  final public function getKeyType(): int {
    return \OPENSSL_KEYTYPE_EC;
  }

  /**
   * Returns the length of each point in the signature, so that we can calculate and verify R and S points properly
   *
   * @internal
   */
  abstract public function getKeyLength(): int;
}
