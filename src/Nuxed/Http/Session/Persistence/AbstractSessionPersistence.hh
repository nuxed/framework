<?hh // strict

namespace Nuxed\Http\Session\Persistence;

use namespace HH\Lib\Str;
use type Nuxed\Http\Session\CacheLimiter;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;
use type Nuxed\Contract\Http\Message\CookieSameSite;
use type Nuxed\Http\Message\Cookie;
use type DateTime;
use type DateInterval;
use function strftime;
use function file_exists;
use function filemtime;
use function bin2hex;
use function random_bytes;
use function time;

abstract class AbstractSessionPersistence
  implements SessionPersistenceInterface {
  /**
   * This unusual past date value is taken from the hhvm source code and
   * used "as is" for consistency.
   *
   * @link https://github.com/facebook/hhvm/blob/master/hphp/runtime/ext/session/ext_session.cpp#L1487
   * @link https://github.com/facebook/hhvm/blob/master/hphp/runtime/ext/session/ext_session.cpp#L1492
   */
  const CACHE_PAST_DATE = 'Thu, 19 Nov 1981 08:52:00 GMT';

  /**
   * Http date format for strftime() and gmstrftime()
   *
   * @link https://github.com/facebook/hhvm/blob/master/hphp/runtime/ext/session/ext_session.cpp#L1431
   */
  const HTTP_DATE_FORMAT = '%a, %d %b %Y %T GMT';

  protected shape(
    'name' => string,
    'lifetime' => int,
    'path' => string,
    'domain' => string,
    'secure' => bool,
    'http_only' => bool,
    'same_site' => CookieSameSite,
    ...
  ) $cookieOptions;
  protected ?CacheLimiter $cacheLimiter;
  protected int $cacheExpire;
  protected string $pathTranslated = '';

  protected function flush(
    SessionInterface $_session,
    ResponseInterface $response,
  ): ResponseInterface {
    return $response->withCookie(
      $this->cookieOptions['name'],
      new Cookie('')
        |> $$->withExpires(DateTime::createFromFormat(
          'D, d M Y H:i:s T',
          static::CACHE_PAST_DATE,
        )),
    );
  }

  protected function createCookie(string $id, ?int $expires = null): Cookie {
    $expires = $expires ?? $this->cookieOptions['lifetime'];

    return new Cookie($id)
      |> $$->withExpires(
        new DateTime()
          |> $$->add(new DateInterval(Str\format('PT%dS', $expires))),
      )
        ->withDomain($this->cookieOptions['domain'])
        ->withPath($this->cookieOptions['path'])
        ->withHttpOnly($this->cookieOptions['http_only'])
        ->withSecure($this->cookieOptions['secure'])
        ->withSameSite($this->cookieOptions['same_site']);
  }

  /**
   * Generate a session identifier.
   */
  protected function generateSessionId(): string {
    return bin2hex(random_bytes(24));
  }

  /**
   * Retrieve the session cookie value.
   *
   * In each case, if the value is not found, it falls back to generating a
   * new session identifier.
   */
  protected function getCookieFromRequest(
    ServerRequestInterface $request,
  ): string {
    return $request->getCookieParams()[$this->cookieOptions['name']] ?? '';
  }

  protected function withCacheHeaders(
    ResponseInterface $response,
  ): ResponseInterface {
    $cacheLimiter = $this->cacheLimiter;

    if (
      null === $cacheLimiter || $this->responseAlreadyHasCacheHeaders($response)
    ) {
      return $response;
    }

    $headers = $this->generateCacheHeaders($cacheLimiter);
    foreach ($headers as $key => $value) {
      if ($value is nonnull) {
        $response = $response->withHeader($key, $value);
      }
    }

    return $response;
  }

  private function responseAlreadyHasCacheHeaders(
    ResponseInterface $response,
  ): bool {
    return (
      $response->hasHeader('Expires') ||
      $response->hasHeader('Last-Modified') ||
      $response->hasHeader('Cache-Control') ||
      $response->hasHeader('Pragma')
    );
  }

  private function generateCacheHeaders(
    CacheLimiter $limiter,
  ): dict<string, ?vec<string>> {
    switch ($limiter) {
      case CacheLimiter::NOCACHE:
        return dict[
          'Expires' => vec[self::CACHE_PAST_DATE],
          'Cache-Control' => vec['no-store', 'no-cache', 'must-revalidate'],
          'Pragma' => vec['no-cache'],
        ];
      case CacheLimiter::PUBLIC:
        $maxAge = 60 * $this->cacheExpire;
        return $this->withLastModifiedAndMaxAge(dict[
          'Expires' => vec[
            strftime(static::HTTP_DATE_FORMAT, time() + $maxAge),
          ],
          'Cache-Control' => vec['public'],
        ]);
      case CacheLimiter::PRIVATE:
        return $this->withLastModifiedAndMaxAge(dict[
          'Expires' => vec[static::CACHE_PAST_DATE],
          'Cache-Control' => vec['private'],
        ]);
      case CacheLimiter::PRIVATE_NO_EXPIRE:
        return $this->withLastModifiedAndMaxAge(dict[
          'Cache-Control' => vec['private'],
        ]);
    }
  }

  /**
   * same behavior as the HHVM engine.
   *
   * @link https://github.com/facebook/hhvm/blob/master/hphp/runtime/ext/session/ext_session.cpp#L1442
   */
  private function withLastModifiedAndMaxAge(
    dict<string, vec<string>> $headers,
  ): dict<string, vec<string>> {
    $maxAge = 60 * $this->cacheExpire;
    $headers['Cache-Control'][] = Str\format('max-age=%d', $maxAge);

    if (
      Str\is_empty($this->pathTranslated) || !file_exists($this->pathTranslated)
    ) {
      return $headers;
    }

    $lastModified =
      strftime(static::HTTP_DATE_FORMAT, filemtime($this->pathTranslated));
    $headers['Last-Modified'] = vec[$lastModified];
    return $headers;
  }
}
