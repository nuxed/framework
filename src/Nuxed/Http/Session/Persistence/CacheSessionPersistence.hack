namespace Nuxed\Http\Session\Persistence;

use namespace HH\Lib\C;
use namespace Facebook\TypeSpec;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;
use type Nuxed\Contract\Cache\CacheInterface;
use type Nuxed\Http\Session\CacheLimiter;
use type Nuxed\Http\Session\Session;

/**
 * Session persistence using a cache item pool.
 *
 * Session identifiers are generated using random_bytes (and casting to hex).
 * During persistence, if the session regeneration flag is true, a new session
 * identifier is created, and the session re-started.
 */
class CacheSessionPersistence extends AbstractSessionPersistence {
  public function __construct(
    private CacheInterface $cache,
    protected this::TCookieOptions $cookieOptions,
    protected ?CacheLimiter $cacheLimiter,
    protected int $cacheExpire,
  ) {}

  <<__Override>>
  public async function initialize(
    ServerRequestInterface $request,
  ): Awaitable<SessionInterface> {
    $this->pathTranslated = (string)(
      $request->getServerParams()['PATH_TRANSLATED'] ?? ''
    );
    $id = $this->getCookieFromRequest($request);
    $sessionData = dict[];
    if ($id !== '') {
      $sessionData = await $this->getSessionDataFromCache($id);
    }
    return new Session($sessionData, $id);
  }

  <<__Override>>
  public async function persist(
    SessionInterface $session,
    ResponseInterface $response,
  ): Awaitable<ResponseInterface> {
    $id = $session->getId();

    // New session? No data? Nothing to do.
    if (
      '' === $id && (0 === C\count($session->items()) || !$session->changed())
    ) {
      return $response;
    }

    if ($session->flushed()) {
      if ($id !== '') {
        $contains = await $this->cache->contains($id);
        if ($contains) {
          await $this->cache->forget($id);
        }
      }

      return $this->flush($session, $response);
    }

    // Regenerate the session if:
    // - we have no session identifier
    // - the session is marked as regenerated
    // - the session has changed (data is different)
    if ('' === $id || $session->regenerated() || $session->changed()) {
      $id = await $this->regenerateSession($id);
    }

    $age = $this->getPersistenceDuration($session);
    await $this->cache->put($id, $session->items(), $age);
    return $this->withCacheHeaders(
      $response->withCookie(
        $this->cookieOptions['name'],
        $this->createCookie($id, $age),
      ),
    );
  }

  /**
   * Regenerates the session.
   *
   * If the cache has an entry corresponding to `$id`, this deletes it.
   *
   * Regardless, it generates and returns a new session identifier.
   */
  private async function regenerateSession(string $id): Awaitable<string> {
    if ('' !== $id) {
      $contains = await $this->cache->contains($id);
      if ($contains) {
        await $this->cache->forget($id);
      }
    }

    return $this->generateSessionId();
  }

  private async function getSessionDataFromCache(
    string $id,
  ): Awaitable<KeyedContainer<string, mixed>> {
    $data = await $this->cache->get($id, dict[]);

    return TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
      ->coerceType($data);
  }
}
