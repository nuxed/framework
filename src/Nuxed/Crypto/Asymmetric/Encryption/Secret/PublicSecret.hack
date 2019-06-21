namespace Nuxed\Crypto\Asymmetric\Encryption\Secret;

use namespace Nuxed\Crypto;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Crypto\Binary;
use namespace Nuxed\Crypto\Asymmetric\Encryption;

final class PublicSecret extends Encryption\Secret {
  const int LENGTH = \SODIUM_CRYPTO_BOX_PUBLICKEYBYTES;
  public function __construct(Crypto\HiddenString $material) {
    if (
      Binary\length($material->toString()) !== static::LENGTH
    ) {
      throw new Crypto\Exception\InvalidKeyException(
        'Encryption public secret must be const(PublicSecret::LENGTH) bytes long',
      );
    }

    parent::__construct($material);
  }

  public static function generate(): this {
    return new self(
      new Crypto\HiddenString(SecureRandom\string(static::LENGTH)),
    );
  }
}
