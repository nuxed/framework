namespace Nuxed\Http\Router\Middleware;

use namespace His\Container;
use namespace Nuxed\Contract\Service;

class DispatchMiddlewareFactory
  implements Service\FactoryInterface<DispatchMiddleware> {
  public function create(
    Container\ContainerInterface $_container,
  ): DispatchMiddleware {
    return new DispatchMiddleware();
  }
}
