namespace Nuxed\Cache\Store;

use namespace HH\Lib\Str;
use namespace Nuxed\Cache\Serializer;

class MCRouterStore extends AbstractStore {
  public function __construct(
    protected \MCRouter $mc,
    string $namespace = '',
    int $defaultTtl = 0,
    protected Serializer\ISerializer $serializer =
      new Serializer\DefaultSerializer(),
  ) {
    parent::__construct($namespace, $defaultTtl);
  }

  <<__Override>>
  protected async function doGet(string $id): Awaitable<dynamic> {
    return $this->serializer->unserialize(await $this->mc->get($id));
  }

  <<__Override>>
  protected async function doDelete(string $id): Awaitable<bool> {
    await $this->mc->del($id);
    return true;
  }

  <<__Override>>
  protected async function doContains(string $id): Awaitable<bool> {
    try {
      await $this->mc->get($id);
      return true;
    } catch (\MCRouterException $e) {
      return false;
    }
  }

  <<__Override>>
  protected async function doStore(
    string $id,
    mixed $value,
    int $ttl = 0,
  ): Awaitable<bool> {
    $value = $this->serializer->serialize($value);
    if ($value is null) {
      return false;
    }

    if (0 >= $ttl) {
      await $this->mc->set($id, $value);
    } else {
      await $this->mc->set($id, $value, 0, $ttl);
    }

    return true;
  }

  <<__Override>>
  protected async function doClear(string $namespace): Awaitable<bool> {
    if (Str\is_empty($namespace)) {
      await $this->mc->flushAll();
      return true;
    }

    return false;
  }
}
