namespace Nuxed\Http\Router;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Router;

class RouterFactory
  implements Service\FactoryInterface<Router\RouterInterface> {
  public function create(Container\ContainerInterface $_container): Router {
    return new Router();
  }
}
