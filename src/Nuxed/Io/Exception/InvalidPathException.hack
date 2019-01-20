namespace Nuxed\Io\Exception;

use type RuntimeException;

/**
 * Exception thrown when an invalid file path is used.
 */
class InvalidPathException
  extends RuntimeException
  implements ExceptionInterface {
}
