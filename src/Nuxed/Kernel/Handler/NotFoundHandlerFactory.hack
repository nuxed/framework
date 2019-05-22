namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

class NotFoundHandlerFactory implements Container\IFactory<NotFoundHandler> {
  public function create(
    Container\IServiceContainer $_container,
  ): NotFoundHandler {
    return new NotFoundHandler();
  }
}
