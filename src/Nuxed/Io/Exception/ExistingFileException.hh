<?hh // strict

namespace Nuxed\Io\Exception;

use type RuntimeException;

/**
 * Exception thrown when a target file destination already exists.
 */
class ExistingFileException
  extends RuntimeException
  implements ExceptionInterface {
}
