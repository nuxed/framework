namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Container;

class NotFoundHandlerFactory implements Container\IFactory<NotFoundHandler> {
  public function create(
    Container\IServiceContainer $_container,
  ): NotFoundHandler {
    return new NotFoundHandler();
  }
}
