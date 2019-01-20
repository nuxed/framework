namespace Nuxed\Container\Exception;

use type Nuxed\Contract\Container\ContainerExceptionInterface;
use type RuntimeException;

class ContainerException
  extends RuntimeException
  implements ContainerExceptionInterface {
}
