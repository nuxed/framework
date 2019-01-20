namespace Nuxed\Io\Exception;

use type RuntimeException;

/**
 * Exception thrown when a file does not exist.
 */
class MissingFileException
  extends RuntimeException
  implements ExceptionInterface {
}
