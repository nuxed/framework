namespace Nuxed\Io\Exception;

use type RuntimeException;

/**
 * Exception thrown when a reading a files fails.
 */
class ReadErrorException
  extends RuntimeException
  implements ExceptionInterface {
}
