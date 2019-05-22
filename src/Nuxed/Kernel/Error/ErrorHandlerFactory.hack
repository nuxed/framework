namespace Nuxed\Kernel\Error;

use namespace Facebook\AutoloadMap;
use namespace Nuxed\Container;
use namespace Nuxed\EventDispatcher;
use namespace Nuxed\Contract;

class ErrorHandlerFactory implements Container\IFactory<IErrorHandler> {
  public function create(
    Container\IServiceContainer $container,
  ): IErrorHandler {
    return new ErrorHandler(
      AutoloadMap\Generated\is_dev(),
      $container->get(EventDispatcher\IEventDispatcher::class),
    );
  }
}
