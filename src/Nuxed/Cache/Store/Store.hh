<?hh // strict

namespace Nuxed\Cache\Store;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use type Nuxed\Cache\Cache;
use type Nuxed\Contract\Service\ResetInterface;
use function pack;
use function mt_rand;
use function base64_encode;
use function time;
use function hash;

abstract class Store implements StoreInterface, ResetInterface {
  protected dict<string, string> $ids = dict[];
  protected dict<string, shape('value' => mixed, 'ttl' => ?num, ...)>
    $deferred = dict[];

  protected string $namespace = '';
  protected string $namespaceVersion = '';
  protected bool $versioningIsEnabled = true;
  protected ?int $maxIdLength = null;

  public function __construct(
    string $namespace = '',
    protected num $defaultTtl = 0,
  ) {
    $this->namespace = Str\is_empty($namespace)
      ? $namespace
      : Cache::validateKey($namespace).':';
  }

  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  abstract protected function doStore(string $id, mixed $value, num $ttl): bool;

  /**
   * Determines whether an item is present in the cache.
   */
  abstract protected function doContains(string $id): bool;

  /**
   * Delete an item from the cache by its unique key.
   */
  abstract protected function doDelete(string $id): bool;

  /**
   * Fetches a value from the cache.
   */
  abstract protected function doGet(string $id): mixed;

  /**
   * Wipes clean the entire cache's keys.
   */
  abstract protected function doClear(string $namespace): bool;

  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  public function store(string $id, mixed $value, ?num $ttl = null): bool {
    $id = $this->getId($id);
    $ttl = $ttl ?? $this->defaultTtl;
    return $this->doStore($id, $value, $ttl);
  }

  /**
   * Determines whether an item is present in the cache.
   */
  public function contains(string $key): bool {
    $id = $this->getId($key);

    if (C\contains_key($this->deferred, $key)) {
      $this->commit();
    }

    return $this->doContains($id);
  }

  /**
   * Delete an item from the cache by its unique key.
   */
  public function delete(string $key): bool {
    $id = $this->getId($key);
    unset($this->deferred[$key]);
    return $this->doDelete($id);
  }

  /**
   * Fetches a value from the cache.
   */
  public function get(string $key): mixed {
    if (0 !== C\count($this->deferred)) {
      $this->commit();
    }

    $id = $this->getId($key);
    return $this->doGet($id);
  }

  public function clear(): bool {
    $this->deferred = dict[];
    if ($cleared = $this->versioningIsEnabled) {
      $namespaceVersion =
        Str\splice(base64_encode(pack('V', mt_rand())), ':', 5);
      try {
        $cleared = $this->store('/'.$this->namespace, $namespaceVersion, 0);
      } catch (\Exception $e) {
        $cleared = false;
      }

      if ($cleared) {
        $this->namespaceVersion = $namespaceVersion;
        $this->ids = dict[];
      }
    }

    return $this->doClear($this->namespace) || $cleared;
  }

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $id, mixed $value, ?num $ttl = null): bool {
    $this->deferred[$id] = shape(
      'value' => $value,
      'ttl' => $ttl,
    );
    return true;
  }

  /**
   * Persists any deferred cache items.
   */
  public function commit(): bool {
    $ok = true;
    foreach ($this->deferred as $key => $value) {
      $ok = $this->store($key, $value['value'], $value['ttl']) && $ok;
    }
    $this->deferred = dict[];

    return $ok;
  }

  /**
   * Enables/disables versioning of items.
   *
   * When versioning is enabled, clearing the cache is atomic and doesn't require listing existing keys to proceed,
   * but old keys may need garbage collection and extra round-trips to the back-end are required.
   *
   * Calling this method also clears the memoized namespace version and thus forces a resynchonization of it.
   *
   * @param bool $enable
   *
   * @return bool the previous state of versioning
   */
  public function enableVersioning(bool $enable = true): bool {
    $wasEnabled = $this->versioningIsEnabled;
    $this->versioningIsEnabled = $enable;
    $this->namespaceVersion = '';
    $this->ids = dict[];

    return $wasEnabled;
  }

  protected function getId(string $key): string {
    if ($this->versioningIsEnabled && '' === $this->namespaceVersion) {
      $this->ids = dict[];
      $this->namespaceVersion = '1/';
      try {
        $this->namespaceVersion = $this->get('/'.$this->namespace) as string;
        if ('1:' === $this->namespaceVersion) {
          $this->namespaceVersion =
            Str\splice(base64_encode(pack('V', time())), ':', 5);
          $this->doStore('@'.$this->namespace, $this->namespaceVersion, 0);
        }
      } catch (\Throwable $e) {
      }
    }

    if (C\contains_key($this->ids, $key)) {
      return $this->namespace.$this->namespaceVersion.$this->ids[$key];
    }

    Cache::validateKey($key);
    $this->ids[$key] = $key;

    if (null === $this->maxIdLength) {
      return $this->namespace.$this->namespaceVersion.$key;
    }
    $id = $this->namespace.$this->namespaceVersion.$key;
    $max = $this->maxIdLength as int;
    if (Str\length($id) > $max) {
      // Use MD5 to favor speed over security, which is not an issue here
      $this->ids[$key] = $id = Str\splice(
        base64_encode(hash('md5', $key, true)),
        ':',
        -(Str\length($this->namespaceVersion) + 2),
      );
      $id = $this->namespace.$this->namespaceVersion.$id;
    }

    return $id;
  }

  public function reset(): void {
    if (0 !== C\count($this->deferred)) {
      $this->commit();
    }
    $this->namespaceVersion = '';
    $this->ids = dict[];
  }
}
