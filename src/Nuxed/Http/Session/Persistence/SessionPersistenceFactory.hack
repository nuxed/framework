namespace Nuxed\Http\Session\Persistence;

use namespace Nuxed\Container;

final class SessionPersistenceFactory
  implements Container\IFactory<ISessionPersistence> {
  public function __construct(
    private classname<ISessionPersistence> $implementation,
  ) {}

  public function create(
    Container\IServiceContainer $container,
  ): ISessionPersistence {
    return $container->get($this->implementation);
  }
}
