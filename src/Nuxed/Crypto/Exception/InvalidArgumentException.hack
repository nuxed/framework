namespace Nuxed\Crypto\Exception;

<<__Sealed(
  InvalidKeyException::class,
  InvalidSignatureException::class,
  InvalidMessageException::class,
)>>
class InvalidArgumentException
  extends \InvalidArgumentException
  implements IException {}
