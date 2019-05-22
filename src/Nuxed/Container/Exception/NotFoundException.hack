namespace Nuxed\Container\Exception;

use namespace His\Container\Exception;

final class NotFoundException
  extends \Exception
  implements IException, Exception\NotFoundExceptionInterface {}
