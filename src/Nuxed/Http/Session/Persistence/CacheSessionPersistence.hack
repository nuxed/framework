namespace Nuxed\Http\Session\Persistence;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;
use type Nuxed\Contract\Cache\CacheInterface;
use type Nuxed\Contract\Http\Message\CookieSameSite;
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
    protected shape(
      'name' => string,
      'lifetime' => int,
      'path' => string,
      'domain' => string,
      'secure' => bool,
      'http_only' => bool,
      'same_site' => CookieSameSite,
      ...
    ) $cookieOptions,
    protected ?CacheLimiter $cacheLimiter,
    protected int $cacheExpire,
  ) {}

  <<__Override>>
  public function initialize(
    ServerRequestInterface $request,
  ): SessionInterface {
    $this->pathTranslated =
      (string)($request->getServerParams()['PATH_TRANSLATED'] ?? '');
    $id = $this->getCookieFromRequest($request);
    $sessionData = $id !== '' ? $this->getSessionDataFromCache($id) : dict[];
    $session = new Session($sessionData, $id);
    $session->expire($this->cookieOptions['lifetime']);
    return $session;
  }

  <<__Override>>
  public function persist(
    SessionInterface $session,
    ResponseInterface $response,
  ): ResponseInterface {
    $id = $session->getId();

    if ($session->flushed()) {
      if (!Str\is_empty($id)) {
        $this->cache->contains($id) && $this->cache->forget($id);
      }

      return $this->flush($session, $response);
    }

    // New session? No data? Nothing to do.
    if (
      Str\is_empty($id) &&
      (C\is_empty($session->items()) || !$session->changed())
    ) {
      return $response;
    }

    // Regenerate the session if:
    // - we have no session identifier
    // - the session is marked as regenerated
    // - the session has changed (data is different)
    if (Str\is_empty($id) || $session->regenerated() || $session->changed()) {
      $id = $this->regenerateSession($id);
    }

    $this->cache->put($id, $session->items(), $session->age());

    return $this->withCacheHeaders(
      $response->withCookie(
        $this->cookieOptions['name'],
        $this->createCookie($id, $session->age()),
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
  private function regenerateSession(string $id): string {
    if (!Str\is_empty($id) && $this->cache->contains($id)) {
      $this->cache->forget($id);
    }
    return $this->generateSessionId();
  }

  private function getSessionDataFromCache(
    string $id,
  ): KeyedContainer<string, mixed> {
    /* HH_IGNORE_ERROR[4110] */
    return $this->cache->get($id, dict[]);
  }
}
