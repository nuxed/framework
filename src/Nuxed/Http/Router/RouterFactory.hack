namespace Nuxed\Http\Router;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

class RouterFactory implements Container\IFactory<IRouter> {
  public function create(Container\IServiceContainer $_container): Router {
    return new Router();
  }
}
