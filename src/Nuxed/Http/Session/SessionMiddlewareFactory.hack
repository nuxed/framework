namespace Nuxed\Http\Session;

use namespace Nuxed\Container;

class SessionMiddlewareFactory
  implements Container\IFactory<SessionMiddleware> {
  public function create(
    Container\IServiceContainer $container,
  ): SessionMiddleware {
    return new SessionMiddleware(
      $container->get(Persistence\ISessionPersistence::class),
    );
  }
}
