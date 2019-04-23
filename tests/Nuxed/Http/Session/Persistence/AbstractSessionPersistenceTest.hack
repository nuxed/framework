namespace Nuxed\Test\Http\Session\Persistence;

use namespace Nuxed\Cache;
use namespace Nuxed\Http\Session;
use namespace Nuxed\Http\Message;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use type Nuxed\Contract\Http\Message\CookieSameSite;
use function Facebook\FBExpect\expect;
use function time;

type TCookieOptions = shape(
  'name' => string,
  'lifetime' => int,
  'path' => string,
  'domain' => string,
  'secure' => bool,
  'http_only' => bool,
  'same_site' => CookieSameSite,
  ...
);

abstract class AbstractSessionPersistenceTest extends HackTest {
  <<DataProvider('providePersistenceConfigData')>>
  public async function testInitialize(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
  ): Awaitable<void> {
    $persistence = await $this->createSessionPersistence(
      $cookie,
      $limiter,
      $expiry,
    );
    $request = new Message\ServerRequest('GET', new Message\Uri());
    $session = await $persistence->initialize($request);
    expect($session->items())->toBeEmpty();

    $persistence = await $this->createSessionPersistenceWithPreviousData(
      $cookie,
      $limiter,
      $expiry,
      'baz',
      dict['foo' => 'bar'],
    );
    $request = $request->withCookieParams(dict[
      $cookie['name'] => 'baz',
    ]);
    $session = await $persistence->initialize($request);
    expect($session->items())->toBeSame(dict['foo' => 'bar']);
    expect($session->getId())->toBeSame('baz');
  }

  <<DataProvider('providePersistenceConfigData')>>
  public async function testPersist(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
  ): Awaitable<void> {
    $persistence = await $this->createSessionPersistenceWithPreviousData(
      $cookie,
      $limiter,
      $expiry,
      'foo',
      dict['foo' => 'bar'],
    );
    $request = new Message\ServerRequest('GET', new Message\Uri())
      |> $$->withCookieParams(dict[
        $cookie['name'] => 'foo',
      ]);

    $session = await $persistence->initialize($request);
    expect($session->getId())->toBeSame('foo');
    $session->set('a', 'b');
    $response = await $persistence->persist($session, Message\Response\empty());
    $httpCookie = $response->getCookie($cookie['name']);
    expect($httpCookie)->toNotBeNull();
    $httpCookie as nonnull;
    expect($httpCookie->getValue())->toNotBeSame('foo');
    if ($cookie['lifetime'] > 0) {
      expect($httpCookie->getExpires()?->getTimestamp() as int)
        ->toBeLessThanOrEqualTo(time() + $cookie['lifetime']);
    }
  }

  <<DataProvider('providePersistenceConfigData')>>
  public async function testPersistWithUnchagnedSession(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
  ): Awaitable<void> {
    $persistence = await $this->createSessionPersistence(
      $cookie,
      $limiter,
      $expiry,
    );
    $request = new Message\ServerRequest('GET', new Message\Uri());
    $session = await $persistence->initialize($request);
    $originalResponse = Message\Response\empty();
    $response = await $persistence->persist($session, $originalResponse);
    expect($response)->toBeSame($originalResponse);
  }

  <<DataProvider('providePersistenceConfigData')>>
  public async function testPersistWithFlushedSession(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
  ): Awaitable<void> {
    $persistence = await $this->createSessionPersistenceWithPreviousData(
      $cookie,
      $limiter,
      $expiry,
      'foo',
      dict['foo' => 'bar'],
    );
    $request = new Message\ServerRequest('GET', new Message\Uri())
      |> $$->withCookieParams(dict[$cookie['name'] => 'baz']);
    $session = await $persistence->initialize($request);
    $session->flush();
    expect($session->flushed())->toBeTrue();
    $originalResponse = Message\Response\empty();
    $response = await $persistence->persist($session, $originalResponse);
    expect($response)->toNotBeSame($originalResponse);
    $httpCookie = $response->getCookie($cookie['name']);
    expect($httpCookie)->toNotBeNull();
    expect($httpCookie?->getExpires())->toNotBeNull();
    expect($httpCookie?->getExpires()?->getTimestamp() as num)->toBeLessThan(
      time(),
    );
  }

  <<DataProvider('providePersistenceConfigData')>>
  public async function testPersistDoesntSetCacheHeadersIfCacheLimiterIsMissing(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $_,
    int $expiry,
  ): Awaitable<void> {
    $persistence = await $this->createSessionPersistenceWithPreviousData(
      $cookie,
      null,
      $expiry,
      'foo',
      dict['foo' => 'bar'],
    );
    $request = new Message\ServerRequest('GET', new Message\Uri())
      |> $$->withCookieParams(dict[$cookie['name'] => 'baz']);
    $session = await $persistence->initialize($request);
    $session->set('a', 'b');
    $originalResponse = Message\Response\empty();
    $response = await $persistence->persist($session, $originalResponse);
    expect($response)->toNotBeSame($originalResponse);
    expect($response->hasHeader('Expires'))->toBeFalse();
    expect($response->hasHeader('Cache-Control'))->toBeFalse();
    expect($response->hasHeader('Pragma'))->toBeFalse();
    expect($response->hasHeader('Last-Modified'))->toBeFalse();
  }

  <<DataProvider('providePersistenceConfigData')>>
  public async function testPersistDoesntChangeCacheHeaders(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $_,
    int $expiry,
  ): Awaitable<void> {
    $persistence = await $this->createSessionPersistenceWithPreviousData(
      $cookie,
      null,
      $expiry,
      'foo',
      dict['foo' => 'bar'],
    );
    $request = new Message\ServerRequest('GET', new Message\Uri())
      |> $$->withCookieParams(dict[$cookie['name'] => 'baz']);
    $session = await $persistence->initialize($request);
    $session->set('a', 'b');
    $originalResponse = Message\Response\empty()
      |> $$->withAddedHeader('Expires', vec['foo'])
      |> $$->withAddedHeader('Pragma', vec['foo']);
    $response = await $persistence->persist($session, $originalResponse);
    expect($response)->toNotBeSame($originalResponse);
    expect($response->getHeaderLine('Expires'))->toBeSame('foo');
    expect($response->getHeaderLine('Pragma'))->toBeSame('foo');
    expect($response->hasHeader('Cache-Control'))->toBeFalse();
    expect($response->hasHeader('Last-Modified'))->toBeFalse();
  }

  abstract protected function createSessionPersistence(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
  ): Awaitable<Session\Persistence\SessionPersistenceInterface>;

  abstract public function createSessionPersistenceWithPreviousData(
    TCookieOptions $cookie,
    ?Session\CacheLimiter $limiter,
    int $expiry,
    string $id,
    KeyedContainer<string, mixed> $data,
  ): Awaitable<Session\Persistence\SessionPersistenceInterface>;

  public function providePersistenceConfigData(
  ): Container<(TCookieOptions, ?Session\CacheLimiter, int)> {
    return vec[
      tuple(
        shape(
          'name' => 'foo',
          'lifetime' => 0,
          'path' => '/',
          'domain' => 'example.com',
          'secure' => true,
          'http_only' => false,
          'same_site' => CookieSameSite::STRICT,
        ),
        null,
        120,
      ),
      tuple(
        shape(
          'name' => 'bar',
          'lifetime' => -1,
          'path' => '/',
          'domain' => 'example.com',
          'secure' => false,
          'http_only' => true,
          'same_site' => CookieSameSite::LAX,
        ),
        null,
        0,
      ),
      tuple(
        shape(
          'name' => 'baz',
          'lifetime' => 36000,
          'path' => '/',
          'domain' => 'example.com',
          'secure' => true,
          'http_only' => true,
          'same_site' => CookieSameSite::STRICT,
        ),
        Session\CacheLimiter::PUBLIC,
        120,
      ),
      tuple(
        shape(
          'name' => 'qux',
          'lifetime' => 120,
          'path' => '/',
          'domain' => 'example.com',
          'secure' => true,
          'http_only' => false,
          'same_site' => CookieSameSite::STRICT,
        ),
        Session\CacheLimiter::PRIVATE_NO_EXPIRE,
        120,
      ),
      tuple(
        shape(
          'name' => 'foobar',
          'lifetime' => 120,
          'path' => '/',
          'domain' => 'example.com',
          'secure' => false,
          'http_only' => false,
          'same_site' => CookieSameSite::STRICT,
        ),
        Session\CacheLimiter::PRIVATE,
        120,
      ),
      tuple(
        shape(
          'name' => 'bazqux',
          'lifetime' => 0,
          'path' => '/',
          'domain' => 'example.com',
          'secure' => false,
          'http_only' => true,
          'same_site' => CookieSameSite::LAX,
        ),
        Session\CacheLimiter::NOCACHE,
        120,
      ),
    ];
  }
}
