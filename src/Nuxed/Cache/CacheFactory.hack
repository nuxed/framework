namespace Nuxed\Cache;

use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Cache;
use namespace Nuxed\Contract\Log;
use namespace His\Container;

class CacheFactory implements Service\FactoryInterface<Cache\CacheInterface> {
  public function create(
    Container\ContainerInterface $container,
  ): Cache\CacheInterface {
    if ($container->has(Log\LoggerInterface::class)) {
      $logger = $container->get(Log\LoggerInterface::class);
    } else {
      $logger = new Log\NullLogger();
    }

    return new Cache($container->get(Store\StoreInterface::class), $logger);
  }
}
