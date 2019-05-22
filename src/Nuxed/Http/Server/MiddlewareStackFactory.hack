namespace Nuxed\Http\Server;

use namespace Nuxed\Container;

final class MiddlewareStackFactory
  implements Container\IFactory<MiddlewareStack> {
  public function create(
    Container\IServiceContainer $_container,
  ): MiddlewareStack {
    return new MiddlewareStack();
  }
}
