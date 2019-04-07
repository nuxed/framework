namespace Nuxed\Http\Router\Middleware;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Message;

class MethodNotAllowedMiddlewareFactory
  implements Service\FactoryInterface<MethodNotAllowedMiddleware> {
  public function create(
    Container\ContainerInterface $container,
  ): MethodNotAllowedMiddleware {
    return new MethodNotAllowedMiddleware(
      $container->get(Message\ResponseFactoryInterface::class),
    );
  }
}
