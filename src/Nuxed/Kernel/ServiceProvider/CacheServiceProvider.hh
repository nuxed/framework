<?hh // strict

namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Cache\Store;
use namespace Nuxed\Cache\Serializer;
use type Nuxed\Contract\Cache\CacheInterface;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Cache\Cache;
use type Nuxed\Cache\Store\StoreInterface;
use type Nuxed\Cache\Serializer\SerializerInterface;
use type Nuxed\Contract\Log\LoggerInterface;
use type Redis;

class CacheServiceProvider extends AbstractServiceProvider {
  protected vec<string> $provides = vec[
    CacheInterface::class,
    SerializerInterface::class,
    StoreInterface::class,
    Store\RedisStore::class,
    Store\ArrayStore::class,
    Store\NullStore::class,
    Store\ApcStore::class,
  ];

  <<__Override>>
  public function register(): void {
    $config = $this->config();

    $this->share(CacheInterface::class, Cache::class)
      ->addArgument(StoreInterface::class)
      ->addArgument(LoggerInterface::class);
    $namespace = $config['cache']['namespace'];
    $defaultTtl = $config['cache']['default_ttl'];

    $this->share(Store\ApcStore::class)
      ->addArgument(new RawArgument($namespace))
      ->addArgument(new RawArgument($defaultTtl))
      ->addArgument(SerializerInterface::class);
    $this->share(Store\ArrayStore::class)
      ->addArgument(new RawArgument($defaultTtl));
    $this->share(Store\RedisStore::class)
      ->addArgument(Redis::class)
      ->addArgument(new RawArgument($namespace))
      ->addArgument(new RawArgument($defaultTtl))
      ->addArgument(SerializerInterface::class);
    $this->share(Store\NullStore::class);

    $this->share(StoreInterface::class, () ==> {
      return $this->getContainer()->get($config['cache']['store']);
    });

    $this->share(Serializer\DefaultSerializer::class);

    $this->share(SerializerInterface::class, () ==> {
      return $this->getContainer()
        ->get($config['cache']['serializer']);
    });
  }
}
