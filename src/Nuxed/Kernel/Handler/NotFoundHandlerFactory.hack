namespace Nuxed\Kernel\Handler;

use namespace His\Container;
use namespace Nuxed\Contract\Service;

class NotFoundHandlerFactory
  implements Service\FactoryInterface<NotFoundHandler> {
  public function create(
    Container\ContainerInterface $_container,
  ): NotFoundHandler {
    return new NotFoundHandler();
  }
}
