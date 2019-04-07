namespace Nuxed\Kernel\Middleware;

use namespace His\Container;
use namespace Nuxed\Kernel\Error;
use namespace Nuxed\Contract\Service;

class ErrorMiddlewareFactory
  implements Service\FactoryInterface<ErrorMiddleware> {
  public function create(
    Container\ContainerInterface $container,
  ): ErrorMiddleware {
    return new ErrorMiddleware($container->get(Error\ErrorHandler::class));
  }
}
