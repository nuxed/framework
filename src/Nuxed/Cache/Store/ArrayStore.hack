namespace Nuxed\Cache\Store;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use function microtime;

class ArrayStore extends Store {
  public function __construct(
    int $defaultTtl = 0,
    protected dict<string, shape(
      'value' => mixed,
      'expiry' => float,
      ...
    )> $cache = dict[],
  ) {
    parent::__construct('', $defaultTtl);
  }

  <<__Override>>
  public async function doStore(
    string $id,
    mixed $value,
    int $ttl = 0,
  ): Awaitable<bool> {
    $this->cache[$id] = shape(
      'value' => $value,
      'expiry' => 0 === $ttl ? 0.0 : microtime(true) + $ttl,
    );

    return true;
  }

  <<__Override>>
  public async function doContains(string $id): Awaitable<bool> {
    if (!C\contains_key($this->cache, $id)) {
      return false;
    }

    $expiry = $this->cache[$id]['expiry'];

    if (0.0 === $expiry) {
      return true;
    }

    $expired = $expiry <= microtime(true);

    if ($expired) {
      unset($this->cache[$id]);
    }

    return !$expired;
  }

  <<__Override>>
  public async function doDelete(string $id): Awaitable<bool> {
    unset($this->cache[$id]);
    return true;
  }

  <<__Override>>
  public async function doGet(string $id): Awaitable<mixed> {
    return $this->cache[$id]['value'] ?? null;
  }

  <<__Override>>
  public async function doClear(string $namespace): Awaitable<bool> {
    if (Str\is_empty($namespace)) {
      $wrappers = await Asio\vmkw(
        $this->cache,
        ($k, $item) ==> {
          return $this->doDelete($k);
        },
      );
    } else {
      $wrappers = await Asio\vmkw(
        $this->cache,
        async ($k, $item) ==> {
          if (Str\starts_with($k, $namespace)) {
            return await $this->doDelete($k);
          }

          return true;
        },
      );
    }
    $ok = true;
    foreach ($wrappers as $wrapper) {
      $ok = $ok && $wrapper->getResult();
    }
    return $ok;
  }
}
