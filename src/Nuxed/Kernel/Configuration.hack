namespace Nuxed\Kernel;

use namespace Nuxed\Cache;
use namespace Nuxed\Log;
use namespace Nuxed\Http\Session;
use namespace Nuxed\Contract\Http;
use namespace Nuxed\Contract\Log as LogContract;
use type DateTimeZone;

type Configuration = shape(
  'app' => shape(
    #───────────────────────────────────────────────────────────────────────#
    # Application Name                                                      #
    #───────────────────────────────────────────────────────────────────────#
    'name' => string,

    #───────────────────────────────────────────────────────────────────────#
    # Application Environment                                               #
    #───────────────────────────────────────────────────────────────────────#
    # This value determines the "environment" your application is currently #
    # running in. This may determine how you prefer to configure various    #
    # services the application utilizes.                                    #
    #───────────────────────────────────────────────────────────────────────#
    'env' => Environment,

    #───────────────────────────────────────────────────────────────────────#
    # Application Debug Mode                                                #
    #───────────────────────────────────────────────────────────────────────#
    # When your application is in debug mode, detailed error messages with  #
    # stack traces will be shown on every error that occurs within your     #
    # application. If disabled, a simple generic error page is shown.       #
    #───────────────────────────────────────────────────────────────────────#
    'debug' => bool,

    #───────────────────────────────────────────────────────────────────────#
    # Application Timezone                                                  #
    #───────────────────────────────────────────────────────────────────────#
    # Here you may specify the default timezone for your application, which #
    # will be used by the HHVM date and date-time functions. We have gone   #
    # ahead and set this to a sensible default for you out of the box.      #
    #───────────────────────────────────────────────────────────────────────#
    'timezone' => DateTimeZone,

    #───────────────────────────────────────────────────────────────────────#
    # Autoloaded Extensions                                                 #
    #───────────────────────────────────────────────────────────────────────#
    # The extensions listed here will be automatically loaded on the        #
    # request to your application. Feel free to add your own extensions to  #
    # this container to grant expanded functionality to your application    #
    #───────────────────────────────────────────────────────────────────────#
    'extensions' => Container<classname<Extension\ExtensionInterface>>,

    ...
  ),

  'session' => shape(
    'cookie' => shape(
      #───────────────────────────────────────────────────────────────────────#
      # Session Cookie Name                                                   #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies the session cookie name. it should only contain             #
      # alphanumeric characters.                                              #
      # Defaults to "hh-session".                                             #
      #───────────────────────────────────────────────────────────────────────#
      'name' => string,

      #───────────────────────────────────────────────────────────────────────#
      # Session Cookie Lifetime                                               #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies the lifetime of the cookie in seconds which is sent to the  #
      # browser. The value 0 means "until the browser is closed".             #
      # Defaults to 0.                                                        #
      #───────────────────────────────────────────────────────────────────────#
      'lifetime' => int,

      #───────────────────────────────────────────────────────────────────────#
      # Session Cookie Path                                                   #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies path to set in the session cookie.                          #
      # Defaults to "/".                                                      #
      #───────────────────────────────────────────────────────────────────────#
      'path' => string,

      #───────────────────────────────────────────────────────────────────────#
      # Session Cookie Domain                                                 #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies the domain to set in the session cookie.                    #
      # Default is none (null) at all meaning the host name of the server     #
      # which generated the cookie according to cookies specification.        #
      #───────────────────────────────────────────────────────────────────────#
      'domain' => ?string,

      #───────────────────────────────────────────────────────────────────────#
      # Secure Session Cookie                                                 #
      #───────────────────────────────────────────────────────────────────────#
      # Specifies whether the cookie should only be sent over secure          #
      # connections.                                                          #
      # Defaults to false.                                                    #
      #───────────────────────────────────────────────────────────────────────#
      'secure' => bool,

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
      'http_only' => bool,

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
      'same_site' => Http\Message\CookieSameSite,

      ...
    ),

    #───────────────────────────────────────────────────────────────────────#
    # Session Cache Limiter                                                 #
    #───────────────────────────────────────────────────────────────────────#
    # pecifies the cache control method used for session pages.             #
    # Defaults to null (won't send any cache headers).                      #
    #───────────────────────────────────────────────────────────────────────#
    'cache-limiter' => ?Session\CacheLimiter,

    #───────────────────────────────────────────────────────────────────────#
    # Session Page Cache Expiry                                             #
    #───────────────────────────────────────────────────────────────────────#
    # Specifies time-to-live for cached session pages in minutes, This has  #
    # This has no effect for CacheLimiter::NOCACHE.                         #
    # Defaults to 180                                                       #
    #───────────────────────────────────────────────────────────────────────#
    'cache-expire' => int,

    #───────────────────────────────────────────────────────────────────────#
    # Session Persistence                                                   #
    #───────────────────────────────────────────────────────────────────────#
    # Specifies the session persistence implementation to use.              #
    # Defaults to the native session persistence.                           #
    #───────────────────────────────────────────────────────────────────────#
    'persistence' => classname<Session\Persistence\SessionPersistenceInterface>,

    ...
  ),

  'cache' => shape(
    #───────────────────────────────────────────────────────────────────────#
    # Cache Store                                                           #
    #───────────────────────────────────────────────────────────────────────#
    # This option controls the cache store that gets used while using       #
    # the cache component.                                                  #
    #───────────────────────────────────────────────────────────────────────#
    'store' => classname<Cache\Store\StoreInterface>,

    #───────────────────────────────────────────────────────────────────────#
    # Cache Items Serializer                                                #
    #───────────────────────────────────────────────────────────────────────#
    # Define the serializer to use for serializing the cache items value    #
    #───────────────────────────────────────────────────────────────────────#
    'serializer' => classname<Cache\Serializer\SerializerInterface>,

    #───────────────────────────────────────────────────────────────────────#
    # Cache Namespace                                                       #
    #───────────────────────────────────────────────────────────────────────#
    # When utilizing a RAM based store such as APC or Memcached,            #
    # there might be other applications utilizing the same cache. So, we'll #
    # specify a unique value to use as the namespace so we can avoid        #
    # colloisions.                                                          #
    #───────────────────────────────────────────────────────────────────────#
    'namespace' => string,

    #───────────────────────────────────────────────────────────────────────#
    # Default Cache TTL ( Time To Live )                                    #
    #───────────────────────────────────────────────────────────────────────#
    # Here we define the default ttl for cached items.                      #
    #───────────────────────────────────────────────────────────────────────#
    'default_ttl' => int,

    ...
  ),

  'log' => shape(
    #───────────────────────────────────────────────────────────────────────#
    # Log Handlers                                                          #
    #───────────────────────────────────────────────────────────────────────#
    # You may define as much log handlers as you want here.                 #
    #───────────────────────────────────────────────────────────────────────#
    'handlers' => Container<classname<Log\Handler\HandlerInterface>>,

    #───────────────────────────────────────────────────────────────────────#
    # Log Processors                                                        #
    #───────────────────────────────────────────────────────────────────────#
    # Log processors process the log record before passing it to the        #
    # handlers, allowing you to add extra information to the record.        #
    #───────────────────────────────────────────────────────────────────────#
    'processors' => Container<classname<Log\Processor\ProcessorInterface>>,

    #───────────────────────────────────────────────────────────────────────#
    # Handlers Options                                                      #
    #───────────────────────────────────────────────────────────────────────#
    # Here we define the options for all the log handlers.                  #
    #───────────────────────────────────────────────────────────────────────#
    'options' => shape(
      'syslog' => shape(
        'ident' => string,
        'facility' => Log\Handler\SysLogFacility,
        'level' => LogContract\LogLevel,
        'bubble' => bool,
        'options' => int,
        'formatter' => classname<Log\Formatter\FormatterInterface>,
        ...
      ),
      'rotating-file' => shape(
        'filename' => string,
        'max-files' => int,
        'level' => LogContract\LogLevel,
        'bubble' => bool,
        'file-permission' => ?int,
        'use-lock' => bool,
        'formatter' => classname<Log\Formatter\FormatterInterface>,
        ...
      ),
      'stream' => shape(
        'url' => string,
        'level' => LogContract\LogLevel,
        'bubble' => bool,
        'file-permission' => ?int,
        'use-lock' => bool,
        'formatter' => classname<Log\Formatter\FormatterInterface>,
        ...
      ),
      ...
    ),
    ...
  ),

  'services' => shape(
    #───────────────────────────────────────────────────────────────────────#
    # Redis Database                                                        #
    #───────────────────────────────────────────────────────────────────────#
    # Redis is an open source, fast, and advanced key-value store that also #
    # provides a richer body of commands than a typical key-value system    #
    # such as APC or Memcached.                                             #
    # These configurations are use for caching and cache-based session      #
    # persistence                                                           #
    #───────────────────────────────────────────────────────────────────────#
    'redis' => shape(
      'host' => string,
      'port' => int,
      'database' => ?int,
      'password' => ?string,
      'timeout' => int,
      ...
    ),

    #───────────────────────────────────────────────────────────────────────#
    # Mysql Connection                                                      #
    #───────────────────────────────────────────────────────────────────────#
    # HHVM Provides an asynchronous Mysql client, Nuxed makes it easy to    #
    # use this client within your application by creating an                #
    # AsyncMysqlConnectionPool instance and a new connection  everytime     #
    # you request the connection instance from the container.               #
    # You can access the mysql connection from the container like this :    #
    # <code>                                                                #
    #     $database = $container->get(AsyncMysqlConnection::class)          #
    #             as AsyncMysqlConnection;                                  #
    # </code>                                                               #
    # You can also access the connection pool like this :                   #
    # <code>                                                                #
    #     $pool = $container->get(AsyncMysqlConnectionPool::class)          #
    #           as AsyncMysqlConnectionPool;                                #
    # </code>                                                               #
    #                                                                       #
    # More information about pool configuration can be found here :         #
    # https://docs.hhvm.com                                                 #
    #    /hack/reference/class/AsyncMysqlConnectionPool/__construct/        #
    #───────────────────────────────────────────────────────────────────────#
    'mysql' => shape(
      'pool' => shape(
        'per_key_connection_limit' => int,
        'pool_connection_limit' => int,
        'idle_timeout_micros' => int,
        'age_timeout_micros' => int,
        'expiration_policy' => string,
        ...
      ),
      'host' => string,
      'port' => int,
      'database' => string,
      'username' => string,
      'password' => string,
      'timeout-micros' => int,
      'extra-key' => string,
      ...
    ),
    ...
  ),

  ...
);
