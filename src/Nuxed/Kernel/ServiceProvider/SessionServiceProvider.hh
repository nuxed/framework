<?hh // strict

namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Http;
use type Nuxed\Container\Argument\RawArgument;

class SessionServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    Http\Session\SessionMiddleware::class,
    Http\Session\Persistence\SessionPersistenceInterface::class,
    Http\Session\Persistence\NativeSessionPersistence::class,
    Http\Session\Persistence\CacheSessionPersistence::class,
  ];

  <<__Override>>
  public function register(): void {
    $config = $this->config()['session'];

    $this->share(Http\Server\MiddlewareFactory::class)
      ->addArgument(new RawArgument($this->getContainer()));
    $this->share(Http\Session\SessionMiddleware::class)
      ->addArgument(
        Http\Session\Persistence\SessionPersistenceInterface::class,
      );

    $this->share(
      Http\Session\Persistence\SessionPersistenceInterface::class,
      () ==> $this->getContainer()
        ->get($config['persistence']),
    );

    $this->share(Http\Session\Persistence\NativeSessionPersistence::class)
      ->addArgument(new RawArgument($config['cookie']))
      ->addArgument(new RawArgument($config['cache-limiter']))
      ->addArgument(new RawArgument($config['cache-expire']));

    $this->share(Http\Session\Persistence\CacheSessionPersistence::class)
      ->addArgument(new RawArgument($config['cookie']))
      ->addArgument(new RawArgument($config['cache-limiter']))
      ->addArgument(new RawArgument($config['cache-expire']));
  }
}
