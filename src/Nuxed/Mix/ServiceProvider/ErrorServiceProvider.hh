<?hh // strict

namespace Nuxed\Mix\ServiceProvider;

use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Contract\Event\EventDispatcherInterface;
use namespace Nuxed\Mix;

class ErrorServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Mix\Error\ErrorHandlerInterface::class,
    Mix\Middleware\ErrorMiddleware::class,
    Mix\Handler\NotFoundHandler::class,
  ];

  <<__Override>>
  public function register(): void {
    $this->share(Mix\Middleware\ErrorMiddleware::class)
      ->addArgument(Mix\Error\ErrorHandlerInterface::class);

    $this->share(
      Mix\Error\ErrorHandlerInterface::class,
      Mix\Error\ErrorHandler::class,
    )
      ->addArgument(new RawArgument($this->config['app']['debug']))
      ->addArgument(EventDispatcherInterface::class);

    $this->share(Mix\Handler\NotFoundHandler::class);
  }
}
