<?hh // strict

namespace Nuxed\Contract\Cache;

interface CacheInterface {
  /**
   * Determine if an item exists in the cache.
   */
  public function contains(string $key): bool;

  /**
   * Fetches a value from the cache.
   */
  public function get(string $key, mixed $default = null): mixed;

  /**
   * Retrieve a value from the cache and delete it.
   */
  public function pull(string $key, mixed $default = null): mixed;

  /**
   * Store an item in the cache.
   */
  public function put(string $key, mixed $value, ?int $ttl = null): bool;

  /**
   * Store an item in the cache if the key does not exist.
   */
  public function add(string $key, mixed $value, ?int $ttl = null): bool;

  /**
   * Increment the value of an item in the cache.
   */
  public function increment(string $key, num $value = 1): bool;

  /**
   * Decrement the value of an item in the cache.
   */
  public function decrement(string $key, num $value = 1): bool;

  /**
   * Store an item in the cache indefinitely.
   */
  public function forever(string $key, mixed $value): bool;

  /**
   * Get an item from the cache, or execute the given Closure and store the result.
   */
  public function remember(
    string $key,
    (function(): mixed) $callback,
    ?int $ttl = null,
  ): mixed;

  /**
   * Get an item from the cache, or execute the given Closure and store the result forever.
   */
  public function sear(string $key, (function(): mixed) $callback): mixed;

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $key, mixed $value, ?int $ttl = null): bool;

  /**
   * Persists any deferred cache items.
   */
  public function commit(): bool;

  /**
   * Remove an item from the cache.
   */
  public function forget(string $key): bool;

  /**
   * Wipes clean the entire cache's keys.
   */
  public function clear(): bool;
}
