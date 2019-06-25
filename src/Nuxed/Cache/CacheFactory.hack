namespace Nuxed\Cache;

use namespace Nuxed\{Container, Log};

class CacheFactory implements Container\IFactory<ICache> {
  public function create(Container\IServiceContainer $container): ICache {
    if ($container->has(Log\ILogger::class)) {
      $logger = $container->get(Log\ILogger::class);
    } else {
      $logger = new Log\NullLogger();
    }

    return new Cache($container->get(Store\IStore::class), $logger);
  }
}
