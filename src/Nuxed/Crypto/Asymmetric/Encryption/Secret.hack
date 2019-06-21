namespace Nuxed\Crypto\Asymmetric\Encryption;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Asymmetric;

<<__Sealed(Secret\PublicSecret::class, Secret\PrivateSecret::class)>>
abstract class Secret extends Asymmetric\Secret {
  /**
   * Diffie-Hellman, ECDHE, etc.
   *
   * Get a shared secret from a private key you possess and a public key for
   * the intended message recipient
   */
  final public static function shared(
    Secret\PrivateSecret $private,
    Secret\PublicSecret $public,
  ): Crypto\HiddenString {
    return new Crypto\HiddenString(
      \sodium_crypto_scalarmult($private->toString(), $public->toString()),
    );
  }

  final public static function private(
    Crypto\HiddenString $material,
  ): Secret\PrivateSecret {
    return new Secret\PrivateSecret($material);
  }

  final public static function public(
    Crypto\HiddenString $material,
  ): Secret\PublicSecret {
    return new Secret\PublicSecret($material);
  }
}
