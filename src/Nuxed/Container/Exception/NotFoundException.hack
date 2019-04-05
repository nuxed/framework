namespace Nuxed\Container\Exception;

use namespace His\Container\Exception;
use type Exception;

final class NotFoundException
  extends Exception
  implements ExceptionInterface, Exception\NotFoundExceptionInterface {}
