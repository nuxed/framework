<?hh // strict

namespace Nuxed\Lib\Exception;

use type InvalidArgumentException;

class JsonEncodeException
  extends InvalidArgumentException
  implements ExceptionInterface {
}
