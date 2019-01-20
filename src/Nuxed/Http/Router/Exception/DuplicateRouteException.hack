namespace Nuxed\Http\Router\Exception;

use type DomainException;

class DuplicateRouteException
  extends DomainException
  implements ExceptionInterface {
}
