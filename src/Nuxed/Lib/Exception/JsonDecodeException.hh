<?hh // strict

namespace Nuxed\Lib\Exception;

use type InvalidArgumentException;

class JsonDecodeException
  extends InvalidArgumentException
  implements ExceptionInterface {
}
