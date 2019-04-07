namespace Nuxed\Http\Router\Middleware;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Router;
use namespace Nuxed\Contract\Http\Message;

class ImplicitHeadMiddlewareFactory
  implements Service\FactoryInterface<ImplicitHeadMiddleware> {
  public function create(
    Container\ContainerInterface $container,
  ): ImplicitHeadMiddleware {
    return new ImplicitHeadMiddleware(
      $container->get(Router\RouterInterface::class),
      $container->get(Message\StreamFactoryInterface::class),
    );
  }
}
