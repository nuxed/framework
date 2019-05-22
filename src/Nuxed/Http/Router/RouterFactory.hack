namespace Nuxed\Http\Router;

use namespace Nuxed\Container;

class RouterFactory implements Container\IFactory<IRouter> {
  public function create(Container\IServiceContainer $_container): Router {
    return new Router();
  }
}
