namespace Nuxed\Kernel\Extension;

use namespace Nuxed\{Cache, Container};

final class CacheExtension extends AbstractExtension {
  const type TConfig = shape(
    #───────────────────────────────────────────────────────────────────────#
    # Cache Store                                                           #
    #───────────────────────────────────────────────────────────────────────#
    # This option controls the cache store that gets used while using       #
    # the cache component.                                                  #
    #───────────────────────────────────────────────────────────────────────#
    ?'store' => classname<Cache\Store\IStore>,

    #───────────────────────────────────────────────────────────────────────#
    # Cache Items Serializer                                                #
    #───────────────────────────────────────────────────────────────────────#
    # Define the serializer to use for serializing the cache items value    #
    #───────────────────────────────────────────────────────────────────────#
    ?'serializer' => classname<Cache\Serializer\ISerializer>,

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

    #───────────────────────────────────────────────────────────────────────#
    # Filesystem cache directory                                            #
    #───────────────────────────────────────────────────────────────────────#
    # Here we define the directory to be used by the filesystem cache       #
    # store.                                                                #
    #───────────────────────────────────────────────────────────────────────#
    ?'cache_dir' => string,
    ...
  );

  public function __construct(private this::TConfig $config = shape()) {}

  <<__Override>>
  public function register(Container\ContainerBuilder $builder): void {
    $builder->add(Cache\ICache::class, new Cache\CacheFactory(), true);

    $namespace = Shapes::idx($this->config, 'namespace', '');
    $defaultTtl = Shapes::idx($this->config, 'default_ttl', 0);

    $builder->add(
      Cache\Store\ApcStore::class,
      Container\factory(
        ($container) ==> new Cache\Store\ApcStore(
          $namespace,
          $defaultTtl,
          $container->get(Cache\Serializer\ISerializer::class),
        ),
      ),
      true,
    );

    $builder->add(
      Cache\Store\ArrayStore::class,
      Container\factory(
        ($container) ==> new Cache\Store\ArrayStore($defaultTtl),
      ),
      true,
    );

    $builder->add(
      Cache\Store\RedisStore::class,
      Container\factory(
        ($container) ==> new Cache\Store\RedisStore(
          $container->get(\Redis::class),
          $namespace,
          $defaultTtl,
          $container->get(Cache\Serializer\ISerializer::class),
        ),
      ),
      true,
    );

    $builder->add(
      Cache\Store\FilesystemStore::class,
      Container\factory(
        ($container) ==> new Cache\Store\FilesystemStore(
          Shapes::idx($this->config, 'cache_dir', \sys_get_temp_dir()),
          $namespace,
          $defaultTtl,
          $container->get(Cache\Serializer\ISerializer::class),
        ),
      ),
      true,
    );

    $builder->add(
      Cache\Store\NullStore::class,
      Container\factory(($_) ==> new Cache\Store\NullStore()),
      true,
    );

    $builder->add(
      Cache\Store\IStore::class,
      Container\factory(
        ($container) ==> $container->get(
          Shapes::idx(
            $this->config,
            'store',
            Shapes::keyExists($this->config, 'cache_dir')
              ? Cache\Store\FilesystemStore::class
              : Cache\Store\ArrayStore::class,
          ),
        ),
      ),
      true,
    );

    $builder->add(
      Cache\Serializer\NativeSerializer::class,
      Container\factory(($_) ==> new Cache\Serializer\NativeSerializer()),
      true,
    );

    $builder->add(
      Cache\Serializer\ISerializer::class,
      Container\factory(
        ($container) ==> $container->get(
          Shapes::idx(
            $this->config,
            'serializer',
            Cache\Serializer\NativeSerializer::class,
          ),
        ),
      ),
      true,
    );
  }
}
