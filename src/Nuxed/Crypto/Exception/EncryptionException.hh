<?hh // strict

namespace Nuxed\Crypto\Exception;

use type Nuxed\Contract\Crypto\Exception\EncryptionExceptionInterface;
use type Exception;

class EncryptionException
  extends Exception
  implements ExceptionInterface, EncryptionExceptionInterface {
}
