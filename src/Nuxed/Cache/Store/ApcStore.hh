<?hh // strict

namespace Nuxed\Cache\Store;

use namespace HH\Lib\Str;
use type Nuxed\Cache\Serializer\SerializerInterface;
use type Nuxed\Cache\Serializer\DefaultSerializer;
use type APCIterator;
use function apc_store;
use function apc_exists;
use function apc_delete;
use function apc_fetch;
use function apc_clear_cache;
use function preg_quote;
use const APC_ITER_KEY;

class ApcStore extends Store {
  public function __construct(
    string $namespace = '',
    num $defaultTtl = 0,
    protected SerializerInterface $serializer = new DefaultSerializer(),
  ) {
    parent::__construct($namespace, $defaultTtl);
  }

  <<__Override>>
  public function doStore(string $id, mixed $value, num $ttl = 0): bool {
    return apc_store($id, $this->serializer->serialize($value), $ttl);
  }

  <<__Override>>
  public function doContains(string $id): bool {
    return apc_exists($id);
  }

  <<__Override>>
  public function doDelete(string $id): bool {
    return apc_delete($id);
  }

  <<__Override>>
  public function doGet(string $id): mixed {
    if (!$this->doContains($id)) {
      return null;
    }

    return $this->serializer->unserialize((string)apc_fetch($id));
  }

  <<__Override>>
  public function doClear(string $namespace): bool {
    if (Str\is_empty($namespace)) {
      return apc_clear_cache();
    }

    /* HH_IGNORE_ERROR[2049] */
    $iterator = new APCIterator(
      Str\format('/^%s/', preg_quote($namespace, '/')),
      /* HH_IGNORE_ERROR[2049] */
      /* HH_IGNORE_ERROR[4106] */
      APC_ITER_KEY,
    );

    return apc_delete($iterator);
  }
}
