namespace Nuxed\Kernel\Middleware;

use namespace Nuxed\Container;
use namespace Nuxed\Kernel\Error;
use namespace Nuxed\Contract;

class ErrorMiddlewareFactory implements Container\IFactory<ErrorMiddleware> {
  public function create(
    Container\IServiceContainer $container,
  ): ErrorMiddleware {
    return new ErrorMiddleware($container->get(Error\ErrorHandler::class));
  }
}
