namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Container;
use namespace Nuxed\Kernel;

class ErrorServiceProvider implements Container\ServiceProviderInterface {
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Kernel\Middleware\ErrorMiddleware::class,
      new Kernel\Middleware\ErrorMiddlewareFactory(),
      true,
    );

    $builder->add(
      Kernel\Error\ErrorHandlerInterface::class,
      new Kernel\Error\ErrorHandlerFactory(),
      true,
    );

    $builder->add(
      Kernel\Handler\NotFoundHandler::class,
      new Kernel\Handler\NotFoundHandlerFactory(),
      true,
    );
  }
}
