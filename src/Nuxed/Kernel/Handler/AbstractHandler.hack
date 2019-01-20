namespace Nuxed\Kernel\Handler;

use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Container\ContainerAwareInterface;

abstract class AbstractHandler
  implements RequestHandlerInterface, ContainerAwareInterface {
  use HandlerTrait;
}
