namespace Nuxed\Http\Router\Middleware;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Message;

class ImplicitOptionsMiddlewareFactory
  implements Service\FactoryInterface<ImplicitOptionsMiddleware> {
  public function create(
    Container\ContainerInterface $container,
  ): ImplicitOptionsMiddleware {
    return new ImplicitOptionsMiddleware(
      $container->get(Message\ResponseFactoryInterface::class),
    );
  }
}
