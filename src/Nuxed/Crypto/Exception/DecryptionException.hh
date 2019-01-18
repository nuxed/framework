<?hh // strict

namespace Nuxed\Crypto\Exception;

use type Nuxed\Contract\Crypto\Exception\DecryptionExceptionInterface;
use type Exception;

class DecryptionException
  extends Exception
  implements ExceptionInterface, DecryptionExceptionInterface {
}
