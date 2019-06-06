namespace Nuxed\Http\Session\Persistence;

use namespace HH\Lib\C;
use namespace Nuxed\Cache;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Session;

type ISessionCache = Cache\ICache;

/**
 * Session persistence using a cache item pool.
 *
 * Session identifiers are generated using random_bytes (and casting to hex).
 * During persistence, if the session regeneration flag is true, a new session
 * identifier is created, and the session re-started.
 */
class CacheSessionPersistence extends AbstractSessionPersistence {
  public function __construct(
    private ISessionCache $cache,
    protected this::TCookieOptions $cookieOptions,
    protected ?Session\CacheLimiter $cacheLimiter,
    protected int $cacheExpire,
  ) {}

  <<__Override>>
  public async function initialize(
    Message\ServerRequest $request,
  ): Awaitable<Session\Session> {
    $this->pathTranslated = (string)(
      $request->getServerParams()['PATH_TRANSLATED'] ?? ''
    );
    $id = $this->getCookieFromRequest($request);
    $sessionData = dict[];
    if ($id !== '') {
      $sessionData = await $this->getSessionDataFromCache($id);
    }

    /* HH_IGNORE_ERROR[4110] */
    return new Session\Session($sessionData, $id);
  }

  <<__Override>>
  public async function persist(
    Session\Session $session,
    Message\Response $response,
  ): Awaitable<Message\Response> {
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
