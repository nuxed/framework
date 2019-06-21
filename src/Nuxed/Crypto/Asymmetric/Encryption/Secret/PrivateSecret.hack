namespace Nuxed\Crypto\Asymmetric\Encryption\Secret;

use namespace Nuxed\Crypto;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Crypto\Binary;
use namespace Nuxed\Crypto\Asymmetric\Encryption;

final class PrivateSecret extends Encryption\Secret {
  const int LENGTH = \SODIUM_CRYPTO_BOX_SECRETKEYBYTES;
  public function __construct(Crypto\HiddenString $material) {
    if (
      Binary\length($material->toString()) !== static::LENGTH
    ) {
      throw new Crypto\Exception\InvalidKeyException(
        'Encryption private secret must be const(PrivateSecret::LENGTH) bytes long',
      );
    }

    parent::__construct($material);
  }

  /**
   * See the appropriate derived class.
   */
  public function derivePublicSecret(): PublicSecret {
    $publicKey = \sodium_crypto_box_publickey_from_secretkey($this->toString());
    return new PublicSecret(new Crypto\HiddenString($publicKey));
  }

  public static function generate(): this {
    return new self(
      new Crypto\HiddenString(SecureRandom\string(static::LENGTH)),
    );
  }
}
