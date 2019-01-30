namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Http;
use type Nuxed\Container\Container;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class FlashServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Http\Flash\FlashMessagesMiddleware::class,
  ];

  <<__Override>>
  public function register(Container $container): void {
    $container->share(Http\Flash\FlashMessagesMiddleware::class);
  }
}
