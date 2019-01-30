<?hh // strict

namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Kernel;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use type Nuxed\Container\Container;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use function Facebook\AutoloadMap\Generated\is_dev;

class ErrorServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Kernel\Error\ErrorHandlerInterface::class,
    Kernel\Middleware\ErrorMiddleware::class,
    Kernel\Handler\NotFoundHandler::class,
  ];

  <<__Override>>
  public function register(Container $container): void {
    $container->share(Kernel\Middleware\ErrorMiddleware::class)
      ->addArgument(Kernel\Error\ErrorHandlerInterface::class);

    $container->share(
      Kernel\Error\ErrorHandlerInterface::class,
      Kernel\Error\ErrorHandler::class,
    )
      ->addArgument(new RawArgument(is_dev()))
      ->addArgument(EventDispatcherInterface::class);

    $container->share(Kernel\Handler\NotFoundHandler::class);
  }
}
