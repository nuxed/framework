namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Http;
use namespace Nuxed\Container;

class FlashServiceProvider implements Container\ServiceProviderInterface {
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(
      Http\Flash\FlashMessagesMiddleware::class,
      new Http\Flash\FlashMessagesMiddlewareFactory(),
      true,
    );
  }
}
