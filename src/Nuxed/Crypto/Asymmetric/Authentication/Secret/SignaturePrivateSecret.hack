namespace Nuxed\Crypto\Asymmetric\Authentication\Secret;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Asymmetric\Encryption;
use namespace Nuxed\Crypto\Asymmetric\Authentication;

final class SignaturePrivateSecret extends Authentication\SignatureSecret {
  const int LENGTH = \SODIUM_CRYPTO_SIGN_SECRETKEYBYTES;
  public function __construct(Crypto\HiddenString $material) {
    if (Crypto\Binary\length($material->toString()) !== static::LENGTH) {
      throw new Crypto\Exception\InvalidKeyException(
        'Signature private secret must be const(SignaturePrivateSecret::LENGTH) bytes long',
      );
    }

    parent::__construct($material);
  }

  /**
   * Get an encryption private secret from a signing private secret.
   */
  public function toEncryptionSecret(): Encryption\Secret\PrivateSecret {
    $ed25519_sk = $this->toString();
    $x25519_sk = \sodium_crypto_sign_ed25519_sk_to_curve25519($ed25519_sk);
    return new Encryption\Secret\PrivateSecret(
      new Crypto\HiddenString($x25519_sk),
    );
  }

  /**
   * See the appropriate derived class.
   */
  public function derivePublicSecret(): SignaturePublicSecret {
    $publicKey = \sodium_crypto_sign_publickey_from_secretkey(
      $this->toString(),
    );
    return new SignaturePublicSecret(new Crypto\HiddenString($publicKey));
  }
}
