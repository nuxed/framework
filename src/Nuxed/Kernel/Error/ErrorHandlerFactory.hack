namespace Nuxed\Kernel\Error;

use namespace His\Container;
use namespace Facebook\AutoloadMap;
use namespace Nuxed\Contract\Event;
use namespace Nuxed\Contract\Service;

class ErrorHandlerFactory
  implements Service\FactoryInterface<ErrorHandlerInterface> {
  public function create(
    Container\ContainerInterface $container,
  ): ErrorHandlerInterface {
    return new ErrorHandler(
      AutoloadMap\Generated\is_dev(),
      $container->get(Event\EventDispatcherInterface::class),
    );
  }
}
