namespace Nuxed\Kernel\ServiceProvider;

use namespace Nuxed\Cache\Store;
use namespace Nuxed\Cache\Serializer;
use type Nuxed\Cache\Cache;
use type Nuxed\Cache\Store\StoreInterface;
use type Nuxed\Cache\Serializer\SerializerInterface;
use type Nuxed\Contract\Log\LoggerInterface;
use type Nuxed\Contract\Cache\CacheInterface;
use type Nuxed\Container\Container;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Container\ServiceProvider\AbstractServiceProvider;
use type Redis;
use function md5;

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

  const type TConfig = shape(
    #───────────────────────────────────────────────────────────────────────#
    # Cache Store                                                           #
    #───────────────────────────────────────────────────────────────────────#
    # This option controls the cache store that gets used while using       #
    # the cache component.                                                  #
    #───────────────────────────────────────────────────────────────────────#
    ?'store' => classname<Store\StoreInterface>,

    #───────────────────────────────────────────────────────────────────────#
    # Cache Items Serializer                                                #
    #───────────────────────────────────────────────────────────────────────#
    # Define the serializer to use for serializing the cache items value    #
    #───────────────────────────────────────────────────────────────────────#
    ?'serializer' => classname<Serializer\SerializerInterface>,

    #───────────────────────────────────────────────────────────────────────#
    # Cache Namespace                                                       #
    #───────────────────────────────────────────────────────────────────────#
    # When utilizing a RAM based store such as APC or Memcached,            #
    # there might be other applications utilizing the same cache. So, we'll #
    # specify a unique value to use as the namespace so we can avoid        #
    # colloisions.                                                          #
    #───────────────────────────────────────────────────────────────────────#
    ?'namespace' => string,

    #───────────────────────────────────────────────────────────────────────#
    # Default Cache TTL ( Time To Live )                                    #
    #───────────────────────────────────────────────────────────────────────#
    # Here we define the default ttl for cached items.                      #
    #───────────────────────────────────────────────────────────────────────#
    ?'default_ttl' => int,

    ...
  );

  <<__Override>>
  public function __construct(private this::TConfig $config = shape()) {
    parent::__construct();
  }

  <<__Override>>
  public function register(Container $container): void {
    $container->share(CacheInterface::class, Cache::class)
      ->addArgument(StoreInterface::class)
      ->addArgument(LoggerInterface::class);
    $namespace = Shapes::idx($this->config, 'namespace', md5(__DIR__));
    $defaultTtl = Shapes::idx($this->config, 'default_ttl', 0);

    $container->share(Store\ApcStore::class)
      ->addArgument(new RawArgument($namespace))
      ->addArgument(new RawArgument($defaultTtl))
      ->addArgument(SerializerInterface::class);
    $container->share(Store\ArrayStore::class)
      ->addArgument(new RawArgument($defaultTtl));
    $container->share(Store\RedisStore::class)
      ->addArgument(Redis::class)
      ->addArgument(new RawArgument($namespace))
      ->addArgument(new RawArgument($defaultTtl))
      ->addArgument(SerializerInterface::class);
    $container->share(Store\NullStore::class);

    $container->share(StoreInterface::class, () ==> {
      return $container
        ->get(Shapes::idx($this->config, 'store', Store\ArrayStore::class));
    });

    $container->share(Serializer\DefaultSerializer::class);

    $container->share(SerializerInterface::class, () ==> {
      return $container
        ->get(
          Shapes::idx(
            $this->config,
            'serializer',
            Serializer\DefaultSerializer::class,
          ),
        );
    });
  }
}
