namespace Nuxed\Container\Exception;

use type Nuxed\Contract\Container\NotFoundExceptionInterface;
use type InvalidArgumentException;

class NotFoundException
  extends InvalidArgumentException
  implements NotFoundExceptionInterface {
}
