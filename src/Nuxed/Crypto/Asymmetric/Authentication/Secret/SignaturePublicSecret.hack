namespace Nuxed\Crypto\Asymmetric\Authentication\Secret;

use namespace Nuxed\Crypto;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Crypto\Asymmetric\Encryption;
use namespace Nuxed\Crypto\Asymmetric\Authentication;

final class SignaturePublicSecret extends Authentication\SignatureSecret {
  const int LENGTH = \SODIUM_CRYPTO_SIGN_PUBLICKEYBYTES;
  public function __construct(Crypto\HiddenString $material) {
    if (Crypto\Binary\length($material->toString()) !== static::LENGTH) {
      throw new Crypto\Exception\InvalidKeyException(
        'Signature public secret must be const(SignaturePublicSecret::LENGTH) bytes long',
      );
    }

    parent::__construct($material);
  }

  /**
   * Get an encryption public key from a signing public key.
   */
  public function toEncryptionSecret(): Encryption\Secret\PublicSecret {
    $ed25519_pk = $this->toString();
    $x25519_pk = \sodium_crypto_sign_ed25519_pk_to_curve25519($ed25519_pk);

    return new Encryption\Secret\PublicSecret(
      new Crypto\HiddenString($x25519_pk),
    );
  }

  <<__Override>>
  public static function generate(): this {
    return new self(
      new Crypto\HiddenString(SecureRandom\string(static::LENGTH)),
    );
  }
}
