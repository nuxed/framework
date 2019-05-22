namespace Nuxed\Http\Message\Exception;

/**
 * The HTTP request contains headers with conflicting information.
 */
class ConflictingHeadersException
  extends \UnexpectedValueException
  implements IException {
}
