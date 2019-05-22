namespace Nuxed\Http\Message\Exception;

/**
 * Raised when a user has performed an operation that should be considered
 * suspicious from a security perspective.
 */
class SuspiciousOperationException
  extends \UnexpectedValueException
  implements IException {
}
