namespace Nuxed\Crypto\Asymmetric\Authentication;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Asymmetric;

<<__Sealed(
  Secret\SignaturePublicSecret::class,
  Secret\SignaturePrivateSecret::class,
)>>
abstract class SignatureSecret extends Asymmetric\Secret {
  final public static function private(
    Crypto\HiddenString $material,
  ): Secret\SignaturePrivateSecret {
    return new Secret\SignaturePrivateSecret($material);
  }

  final public static function public(
    Crypto\HiddenString $material,
  ): Secret\SignaturePublicSecret {
    return new Secret\SignaturePublicSecret($material);
  }
}
