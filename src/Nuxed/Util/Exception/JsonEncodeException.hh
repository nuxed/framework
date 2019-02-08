<?hh // strict

namespace Nuxed\Util\Exception;

use type InvalidArgumentException;

class JsonEncodeException
  extends InvalidArgumentException
  implements ExceptionInterface {
}
