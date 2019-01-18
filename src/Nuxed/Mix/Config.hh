<?hh // strict

namespace Nuxed\Mix;

use namespace Nuxed\Lib;
use namespace Nuxed\Cache;
use namespace Nuxed\Log;
use namespace Nuxed\Http\Session;
use namespace Nuxed\Contract\Http;
use namespace Nuxed\Contract\Log as LogContract;
use type DateTimeZone;
use function md5;
use function sys_get_temp_dir;
use const LOG_PID;

final abstract class Config {

  public static function load(
    KeyedContainer<string, mixed> $config,
  ): Configuration {
    /* HH_IGNORE_ERROR[4110] */
    return static::shaped(Lib\Recursive::union(
      $config,
      /* HH_IGNORE_ERROR[4110] */
      static::default(),
    ));
  }

  private static function shaped<Tk as arraykey, Tv>(
    KeyedContainer<Tk, Tv> $c,
  ): darray<Tk, Tv> {
    foreach ($c as $key => $value) {
      if ($value is KeyedContainer<_, _>) {
        /* HH_IGNORE_ERROR[4011] */
        /* HH_IGNORE_ERROR[4110] */
        $c[$key] = static::shaped($value);
      }
    }

    /* HH_IGNORE_ERROR[2049] */
    /* HH_IGNORE_ERROR[4107] */
    return \darray($c);
  }

  private static function default(): Configuration {
    #───────────────────────────────────────────────────────────────────────#
    # Default Configurations                                                #
    #───────────────────────────────────────────────────────────────────────#
    return shape(
      'app' => shape(
        #───────────────────────────────────────────────────────────────────────#
        # Application Name                                                      #
        #───────────────────────────────────────────────────────────────────────#
        'name' => 'Nuxed',

        #───────────────────────────────────────────────────────────────────────#
        # Application Environment                                               #
        #───────────────────────────────────────────────────────────────────────#
        # This value determines the "environment" your application is currently #
        # running in. This may determine how you prefer to configure various    #
        # services the application utilizes.                                    #
        #───────────────────────────────────────────────────────────────────────#
        'env' => Environment::PRODUCTION,

        #───────────────────────────────────────────────────────────────────────#
        # Application Debug Mode                                                #
        #───────────────────────────────────────────────────────────────────────#
        # When your application is in debug mode, detailed error messages with  #
        # stack traces will be shown on every error that occurs within your     #
        # application. If disabled, a simple generic error page is shown.       #
        #───────────────────────────────────────────────────────────────────────#
        'debug' => false,

        #───────────────────────────────────────────────────────────────────────#
        # Application Timezone                                                  #
        #───────────────────────────────────────────────────────────────────────#
        # Here you may specify the default timezone for your application, which #
        # will be used by the HHVM date and date-time functions. We have gone   #
        # ahead and set this to a sensible default for you out of the box.      #
        #───────────────────────────────────────────────────────────────────────#
        'timezone' => new DateTimeZone('UTC'),

        #───────────────────────────────────────────────────────────────────────#
        # Autoloaded Extensions                                                 #
        #───────────────────────────────────────────────────────────────────────#
        # The extensions listed here will be automatically loaded on the        #
        # request to your application. Feel free to add your own extensions to  #
        # this vector to grant expanded functionality to your application       #
        #───────────────────────────────────────────────────────────────────────#
        'extensions' => vec[],
      ),

      'session' => shape(
        'cookie' => shape(
          #───────────────────────────────────────────────────────────────────────#
          # Session Cookie Name                                                   #
          #───────────────────────────────────────────────────────────────────────#
          # Specifies the session cookie name. it should only contain             #
          # alphanumeric characters.                                              #
          # Defaults to "nuxed-session".                                          #
          #───────────────────────────────────────────────────────────────────────#
          'name' => 'nuxed-session',

          #───────────────────────────────────────────────────────────────────────#
          # Session Cookie Lifetime                                               #
          #───────────────────────────────────────────────────────────────────────#
          # Specifies the lifetime of the cookie in seconds which is sent to the  #
          # browser. The value 0 means "until the browser is closed".             #
          # Defaults to 0.                                                        #
          #───────────────────────────────────────────────────────────────────────#
          'lifetime' => 0,

          #───────────────────────────────────────────────────────────────────────#
          # Session Cookie Path                                                   #
          #───────────────────────────────────────────────────────────────────────#
          # Specifies path to set in the session cookie.                          #
          # Defaults to "/".                                                      #
          #───────────────────────────────────────────────────────────────────────#
          'path' => '/',

          #───────────────────────────────────────────────────────────────────────#
          # Session Cookie Domain                                                 #
          #───────────────────────────────────────────────────────────────────────#
          # Specifies the domain to set in the session cookie.                    #
          # Default is none (null) at all meaning the host name of the server     #
          # which generated the cookie according to cookies specification.        #
          #───────────────────────────────────────────────────────────────────────#
          'domain' => null,

          #───────────────────────────────────────────────────────────────────────#
          # Secure Session Cookie                                                 #
          #───────────────────────────────────────────────────────────────────────#
          # Specifies whether the cookie should only be sent over secure          #
          # connections.                                                          #
          # Defaults to false.                                                    #
          #───────────────────────────────────────────────────────────────────────#
          'secure' => false,

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
          'http_only' => true,

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
          'same_site' => Http\Message\CookieSameSite::STRICT,
        ),

        #───────────────────────────────────────────────────────────────────────#
        # Session Cache Limiter                                                 #
        #───────────────────────────────────────────────────────────────────────#
        # pecifies the cache control method used for session pages.             #
        # Defaults to null (won't send any cache headers).                      #
        #───────────────────────────────────────────────────────────────────────#
        'cache-limiter' => Session\CacheLimiter::PRIVATE,

        #───────────────────────────────────────────────────────────────────────#
        # Session Page Cache Expiry                                             #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies time-to-live for cached session pages in minutes, This has  #
        # This has no effect for CacheLimiter::NOCACHE.                         #
        # Defaults to 180                                                       #
        #───────────────────────────────────────────────────────────────────────#
        'cache-expire' => 180,

        #───────────────────────────────────────────────────────────────────────#
        # Session Persistence                                                   #
        #───────────────────────────────────────────────────────────────────────#
        # Specifies the session persistence implementation to use.              #
        # Defaults to the native session persistence.                           #
        #───────────────────────────────────────────────────────────────────────#
        'persistence' => Session\Persistence\NativeSessionPersistence::class,
      ),

      'cache' => shape(
        #───────────────────────────────────────────────────────────────────────#
        # Cache Store                                                           #
        #───────────────────────────────────────────────────────────────────────#
        # This option controls the cache store that gets used while using       #
        # the cache component.                                                  #
        #───────────────────────────────────────────────────────────────────────#
        'store' => Cache\Store\ApcStore::class,

        #───────────────────────────────────────────────────────────────────────#
        # Cache Items Serializer                                                #
        #───────────────────────────────────────────────────────────────────────#
        # Define the serializer to use for serializing the cache items value    #
        #───────────────────────────────────────────────────────────────────────#
        'serializer' => Cache\Serializer\DefaultSerializer::class,

        #───────────────────────────────────────────────────────────────────────#
        # Cache Namespace                                                       #
        #───────────────────────────────────────────────────────────────────────#
        # When utilizing a RAM based store such as APC or Memcached,            #
        # there might be other applications utilizing the same cache. So, we'll #
        # specify a unique value to use as the namespace so we can avoid        #
        # colloisions.                                                          #
        #───────────────────────────────────────────────────────────────────────#
        'namespace' => md5(__FILE__),

        #───────────────────────────────────────────────────────────────────────#
        # Default Cache TTL ( Time To Live )                                    #
        #───────────────────────────────────────────────────────────────────────#
        # Here we define the default ttl for cached items.                      #
        #───────────────────────────────────────────────────────────────────────#
        'default_ttl' => 0,
      ),

      'log' => shape(
        #───────────────────────────────────────────────────────────────────────#
        # Log Handlers                                                          #
        #───────────────────────────────────────────────────────────────────────#
        # You may define as much log handlers as you want here.                 #
        #───────────────────────────────────────────────────────────────────────#
        'handlers' => vec[
          Log\Handler\SysLogHandler::class,
        ],

        #───────────────────────────────────────────────────────────────────────#
        # Log Processors                                                        #
        #───────────────────────────────────────────────────────────────────────#
        # Log processors process the log record before passing it to the        #
        # handlers, allowing you to add extra information to the record.        #
        #───────────────────────────────────────────────────────────────────────#
        'processors' => vec[
          Log\Processor\ContextProcessor::class,
        ],

        #───────────────────────────────────────────────────────────────────────#
        # Handlers Options                                                      #
        #───────────────────────────────────────────────────────────────────────#
        # Here we define the options for all the log handlers.                  #
        #───────────────────────────────────────────────────────────────────────#
        'options' => shape(
          'syslog' => shape(
            'ident' => 'nuxed',
            'facility' => Log\Handler\SysLogFacility::USER,
            'level' => LogContract\LogLevel::DEBUG,
            'bubble' => true,
            'options' => LOG_PID,
            'formatter' => Log\Formatter\LineFormatter::class,
          ),
          'rotating-file' => shape(
            'filename' => sys_get_temp_dir().'/nuxed.log',
            'max-files' => 0,
            'level' => LogContract\LogLevel::DEBUG,
            'bubble' => true,
            'file-permission' => null,
            'use-lock' => false,
            'formatter' => Log\Formatter\LineFormatter::class,
          ),
          'stream' => shape(
            'url' => sys_get_temp_dir().'/nuxed.log',
            'level' => LogContract\LogLevel::DEBUG,
            'bubble' => true,
            'file-permission' => null,
            'use-lock' => false,
            'formatter' => Log\Formatter\LineFormatter::class,
          ),
        ),
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
          'host' => '127.0.0.1',
          'port' => 6379,
          'database' => null,
          'password' => null,
          'timeout' => 0,
        ),

        #───────────────────────────────────────────────────────────────────────#
        # Mysql Connection                                                      #
        #───────────────────────────────────────────────────────────────────────#
        # HHVM Provides an asynchronous Mysql client, Nuxed makes it easy to    #
        # use this client within your application by creating an                #
        # AsyncMysqlConnectionPool instance and create a new connection         #
        # everytime you request the AsyncMysqlClient instance from the          #
        # container.                                                            #
        # You can access the mysql connection from the container like this :    #
        # <code>                                                                #
        #     $database = $container->get(AsyncMysqlClient::class)              #
        #             as AsyncMysqlClient;                                      #
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
            'per_key_connection_limit' => 50,
            'pool_connection_limit' => 5000,
            'idle_timeout_micros' => 4,
            'age_timeout_micros' => 60,
            'expiration_policy' => 'Age',
          ),
          'host' => '127.0.0.1',
          'port' => 3306,
          'database' => 'nuxed',
          'username' => 'nuxed',
          'password' => '',
          'timeout-micros' => -1,
          'extra-key' => '',
        ),
      ),
    );
  }
}
