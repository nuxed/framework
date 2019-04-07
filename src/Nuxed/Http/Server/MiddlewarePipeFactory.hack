namespace Nuxed\Http\Server;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Server;

final class MiddlewarePipeFactory
  implements Service\FactoryInterface<Server\MiddlewarePipeInterface> {
  public function create(
    Container\ContainerInterface $_container,
  ): MiddlewarePipe {
    return new MiddlewarePipe();
  }
}
