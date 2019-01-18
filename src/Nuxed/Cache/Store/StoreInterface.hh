<?hh // strict

namespace Nuxed\Cache\Store;

interface StoreInterface {
  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  public function store(string $id, mixed $value, ?num $ttl = null): bool;

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $id, mixed $value, ?num $ttl = null): bool;

  /**
   * Determines whether an item is present in the cache.
   */
  public function contains(string $id): bool;

  /**
   * Delete an item from the cache by its unique key.
   */
  public function delete(string $id): bool;

  /**
   * Fetches a value from the cache.
   */
  public function get(string $id): mixed;

  /**
   * Wipes clean the entire cache's keys.
   */
  public function clear(): bool;

  /**
   * Persists any deferred cache items.
   */
  public function commit(): bool;
}
