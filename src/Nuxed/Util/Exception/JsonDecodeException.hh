<?hh // strict

namespace Nuxed\Util\Exception;

use type InvalidArgumentException;

class JsonDecodeException
  extends InvalidArgumentException
  implements ExceptionInterface {
}
