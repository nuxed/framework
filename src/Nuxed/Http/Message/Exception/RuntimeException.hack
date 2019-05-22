namespace Nuxed\Http\Message\Exception;

<<__Sealed(
  UnreadableStreamException::class,
  UnwritableStreamException::class,
  UntellableStreamException::class,
  UploadedFileErrorException::class,
  UploadedFileAlreadyMovedException::class,
)>>
class RuntimeException extends \RuntimeException implements IException {
}
