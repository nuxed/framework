namespace Nuxed\Crypto\Symmetric;

use namespace Nuxed\Crypto;

<<__Sealed(Encryption\Secret::class, Authentication\Secret::class)>>
abstract class Secret extends Crypto\Secret {}
