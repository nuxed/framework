namespace Nuxed\Http\Session\Persistence;

use namespace Nuxed\Container;
use namespace Nuxed\Http\Session;

class CacheSessionPersistenceFactory implements Container\IFactory<CacheSessionPersistence> {
  public function __construct(
    protected CacheSessionPersistence::TCookieOptions $cookieOptions,
    protected ?Session\CacheLimiter $cacheLimiter,
    protected int $cacheExpire,
  ) {}

  public function create(
    Container\IServiceContainer $container
  ): CacheSessionPersistence {
    return new CacheSessionPersistence(
      $container->get(ISessionCache::class),
      $this->cookieOptions,
      $this->cacheLimiter,
      $this->cacheExpire,
    );
  }
}
