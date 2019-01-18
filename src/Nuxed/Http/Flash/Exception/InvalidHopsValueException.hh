<?hh // strict

namespace Nuxed\Http\Flash\Exception;

use type InvalidArgumentException;

class InvalidHopsValueException
  extends InvalidArgumentException
  implements ExceptionInterface {
}
