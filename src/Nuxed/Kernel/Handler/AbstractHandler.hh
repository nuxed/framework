<?hh // strict

namespace Nuxed\Kernel\Handler;

use type Nuxed\Contract\Http\Server\RequestHandlerInterface;

abstract class AbstractHandler implements RequestHandlerInterface {
  use HandlerTrait;
}
