namespace Nuxed\Cache\Exception;

use type InvalidArgumentException as ParentException;
use type Nuxed\Contract\Cache\InvalidArgumentExceptionInterface;

class InvalidArgumentException
  extends ParentException
  implements ExceptionInterface, InvalidArgumentExceptionInterface {
}
