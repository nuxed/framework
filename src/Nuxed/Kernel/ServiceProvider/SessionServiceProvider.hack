namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Contract\Http;
use namespace Nuxed\Http\Session;
use type Nuxed\Container\Container;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;

class SessionServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Session\SessionMiddleware::class,
    Session\Persistence\SessionPersistenceInterface::class,
    Session\Persistence\NativeSessionPersistence::class,
    Session\Persistence\CacheSessionPersistence::class,
  ];

  <<__Override>>
  public function __construct(
    private shape(
      ?'cookie' => shape(
        #───────────────────────────────────────────────────────────────────────#
        # Session Cookie Name                                                   #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies the session cookie name. it should only contain             #
        # alphanumeric characters.                                              #
        # Defaults to "hh-session".                                             #
        #───────────────────────────────────────────────────────────────────────#
        ?'name' => string,

        #───────────────────────────────────────────────────────────────────────#
        # Session Cookie Lifetime                                               #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies the lifetime of the cookie in seconds which is sent to the  #
        # browser. The value 0 means "until the browser is closed".             #
        # Defaults to 0.                                                        #
        #───────────────────────────────────────────────────────────────────────#
        ?'lifetime' => int,

        #───────────────────────────────────────────────────────────────────────#
        # Session Cookie Path                                                   #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies path to set in the session cookie.                          #
        # Defaults to "/".                                                      #
        #───────────────────────────────────────────────────────────────────────#
        ?'path' => string,

        #───────────────────────────────────────────────────────────────────────#
        # Session Cookie Domain                                                 #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies the domain to set in the session cookie.                    #
        # Default is none (null) at all meaning the host name of the server     #
        # which generated the cookie according to cookies specification.        #
        #───────────────────────────────────────────────────────────────────────#
        ?'domain' => ?string,

        #───────────────────────────────────────────────────────────────────────#
        # Secure Session Cookie                                                 #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies whether the cookie should only be sent over secure          #
        # connections.                                                          #
        # Defaults to false.                                                    #
        #───────────────────────────────────────────────────────────────────────#
        ?'secure' => bool,

        #───────────────────────────────────────────────────────────────────────#
        # Http Access Only                                                      #
        #───────────────────────────────────────────────────────────────────────#
        # Marks the cookie as accessible only through the HTTP Protocol. this   #
        # means that cookie won't be accessible by scripting langauges, such as #
        # JavaScript. this setting can effectively help to reduce identity      #
        # theft through XSS attacks.                                            #
        # Note: that this is not supported by all browsers.                     #
        # Defaults to false.                                                    #
        #───────────────────────────────────────────────────────────────────────#
        ?'http_only' => bool,

        #───────────────────────────────────────────────────────────────────────#
        # Session Cookie Same Site Policy                                       #
        #───────────────────────────────────────────────────────────────────────#
        # Allows servers to assert that a cookie ought not to be sent along     #
        # with cross-site requests. This assertion allows user agents to        #
        # mitigate the risk of cross-origin information leakage, and provides   #
        # some protection against CSRF attacks.                                 #
        # Note: that this is not supported by all browsers.                     #
        # Note: use Null to disable same-site                                   #
        # Defaults to strict                                                    #
        #───────────────────────────────────────────────────────────────────────#
        ?'same_site' => Http\Message\CookieSameSite,

        ...
      ),

      #───────────────────────────────────────────────────────────────────────#
      # Session Cache Limiter                                                 #
      #───────────────────────────────────────────────────────────────────────#
      # pecifies the cache control method used for session pages.             #
      # Defaults to null (won't send any cache headers).                      #
      #───────────────────────────────────────────────────────────────────────#
      ?'cache-limiter' => ?Session\CacheLimiter,

      #───────────────────────────────────────────────────────────────────────#
      # Session Page Cache Expiry                                             #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies time-to-live for cached session pages in minutes, This has  #
      # This has no effect for CacheLimiter::NOCACHE.                         #
      # Defaults to 180                                                       #
      #───────────────────────────────────────────────────────────────────────#
      ?'cache-expire' => int,

      #───────────────────────────────────────────────────────────────────────#
      # Session Persistence                                                   #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies the session persistence implementation to use.              #
      # Defaults to the native session persistence.                           #
      #───────────────────────────────────────────────────────────────────────#
      ?'persistence' =>
        classname<Session\Persistence\SessionPersistenceInterface>,

      ...
    ) $config = shape(),
  ) {
    parent::__construct();
  }

  <<__Override>>
  public function register(Container $container): void {
    $container->share(Session\SessionMiddleware::class)
      ->addArgument(Session\Persistence\SessionPersistenceInterface::class);

    $container->share(
      Session\Persistence\SessionPersistenceInterface::class,
      () ==> $container
        ->get(
          $this->config['persistence'] ??
            Session\Persistence\NativeSessionPersistence::class,
        ),
    );

    $cookie = shape(
      'name' => $this->config['cookie']['name'] ?? 'hh-session',
      'lifetime' => $this->config['cookie']['lifetime'] ?? 0,
      'path' => $this->config['cookie']['path'] ?? '/',
      'domain' => $this->config['cookie']['domain'] ?? null,
      'http_only' => $this->config['cookie']['http_only'] ?? false,
      'secure' => $this->config['cookie']['secure'] ?? false,
      'same_site' => $this->config['cookie']['same_site'] ??
        Http\Message\CookieSameSite::STRICT,
    );
    $cl = $this->config['cache-limiter'] ?? Session\CacheLimiter::PRIVATE;
    $ce = $this->config['cache-expire'] ?? 180;

    $container->share(Session\Persistence\NativeSessionPersistence::class)
      ->addArgument(new RawArgument($cookie))
      ->addArgument(new RawArgument($cl))
      ->addArgument(new RawArgument($ce));

    $container->share(Session\Persistence\CacheSessionPersistence::class)
      ->addArgument(new RawArgument($cookie))
      ->addArgument(new RawArgument($cl))
      ->addArgument(new RawArgument($ce));
  }
}
