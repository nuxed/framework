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

  final public static function generate(
  ): (Secret\SignaturePrivateSecret, Secret\SignaturePublicSecret) {
    // Encryption keypair
    $kp = \sodium_crypto_sign_keypair();
    $private = \sodium_crypto_sign_secretkey($kp);

    \sodium_memzero(&$kp);
    return new Secret\SignaturePrivateSecret(new Crypto\HiddenString($private))
      |> tuple($$, $$->derivePublicSecret());
  }
}
