namespace Nuxed\Test\Http\Session\Persistence;

use namespace HH\Asio;
use namespace Nuxed\Cache;
use namespace Nuxed\Http\Session;

class CacheSessionPersistenceTest extends AbstractSessionPersistenceTest {
  protected async function createSessionPersistence(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
  ): Awaitable<Session\Persistence\ISessionPersistence> {
    $cache = new Cache\Cache(new Cache\Store\ArrayStore());
    $persistence = new Session\Persistence\CacheSessionPersistence(
      $cache,
      $cookie,
      $limiter,
      $expiry,
    );
    return $persistence;
  }

  public async function createSessionPersistenceWithPreviousData(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
    string $id,
    KeyedContainer<string, mixed> $data,
  ): Awaitable<Session\Persistence\ISessionPersistence> {
    $cache = new Cache\Cache(new Cache\Store\ArrayStore());
    $persistence = new Session\Persistence\CacheSessionPersistence(
      $cache,
      $cookie,
      $limiter,
      $expiry,
    );
    Asio\join($cache->forever($id, $data));
    return $persistence;
  }
}
