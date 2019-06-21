namespace Nuxed\Crypto\Asymmetric;

use namespace Nuxed\Crypto;

<<__Sealed(Encryption\Secret::class, Authentication\SignatureSecret::class)>>
abstract class Secret extends Crypto\Secret {
}
