namespace Nuxed\Http\Message\Exception;

final class UploadedFileAlreadyMovedException extends RuntimeException {
  public function __construct(
    string $message = 'Cannot retrieve stream after it has already moved.',
    int $code = 0,
    ?\Exception $previous = null,
  ) {
    parent::__construct($message, $code, $previous);
  }
}
