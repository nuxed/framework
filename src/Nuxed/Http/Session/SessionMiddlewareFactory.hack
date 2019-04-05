namespace Nuxed\Http\Session;

use namespace His\Container;
use namespace Nuxed\Contract\Service;

class SessionMiddlewareFactory
  implements Service\FactoryInterface<SessionMiddleware> {
  public function create(
    Container\ContainerInterface $container,
  ): SessionMiddleware {
    return new SessionMiddleware(
      $container->get(Persistence\SessionPersistenceInterface::class),
    );
  }
}
