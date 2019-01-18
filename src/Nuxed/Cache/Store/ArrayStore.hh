<?hh // strict

namespace Nuxed\Cache\Store;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use function microtime;

type Item = shape(
  'value' => mixed,
  'expiry' => float,
  ...
);

class ArrayStore extends Store {
  public function __construct(
    num $defaultTtl = 0,
    protected dict<string, Item> $cache = dict[],
  ) {
    parent::__construct('', $defaultTtl);
  }

  <<__Override>>
  public function doStore(string $id, mixed $value, num $ttl = 0): bool {
    $this->cache[$id] = shape(
      'value' => $value,
      'expiry' => 0 === $ttl ? 0.0 : microtime(true) + $ttl,
    );

    return true;
  }

  <<__Override>>
  public function doContains(string $id): bool {
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
  public function doDelete(string $id): bool {
    unset($this->cache[$id]);
    return true;
  }

  <<__Override>>
  public function doGet(string $id): mixed {
    return $this->cache[$id]['value'] ?? null;
  }

  <<__Override>>
  public function doClear(string $namespace): bool {
    $ok = true;
    foreach ($this->cache as $key => $item) {
      if (Str\is_empty($namespace) || Str\starts_with($key, $namespace)) {
        $ok = $this->delete($key) && $ok;
      }
    }
    return $ok;
  }
}
