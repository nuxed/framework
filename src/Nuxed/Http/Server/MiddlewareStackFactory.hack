namespace Nuxed\Http\Server;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;
use namespace Nuxed\Contract\Http\Server;

final class MiddlewareStackFactory
  implements Container\IFactory<MiddlewareStack> {
  public function create(
    Container\IServiceContainer $_container,
  ): MiddlewareStack {
    return new MiddlewareStack();
  }
}
