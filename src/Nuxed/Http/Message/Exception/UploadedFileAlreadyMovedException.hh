<?hh // strict

namespace Nuxed\Http\Message\Exception;

use type RuntimeException;
use type Exception;

class UploadedFileAlreadyMovedException
  extends RuntimeException
  implements ExceptionInterface {
  public function __construct(
    string $message = 'Cannot retrieve stream after it has already moved',
    int $code = 0,
    ?Exception $previous = null,
  ) {
    parent::__construct($message, $code, $previous);
  }
}
