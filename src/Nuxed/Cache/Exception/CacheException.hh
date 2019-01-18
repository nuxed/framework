<?hh // strict

namespace Nuxed\Cache\Exception;

use type Nuxed\Contract\Cache\CacheExceptionInterface;
use type Exception;

class CacheException
  extends Exception
  implements ExceptionInterface, CacheExceptionInterface {
}
