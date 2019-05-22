namespace Nuxed\Cache\Store;

interface IStore {
  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  public function store<T>(
    string $id,
    T $value,
    ?int $ttl = null,
  ): Awaitable<bool>;

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer<T>(string $id, T $value, ?int $ttl = null): bool;

  /**
   * Determines whether an item is present in the cache.
   */
  public function contains(string $id): Awaitable<bool>;

  /**
   * Delete an item from the cache by its unique key.
   */
  public function delete(string $id): Awaitable<bool>;

  /**
   * Fetches a value from the cache.
   */
  public function get(string $id): Awaitable<mixed>;

  /**
   * Wipes clean the entire cache's keys.
   */
  public function clear(): Awaitable<bool>;

  /**
   * Persists any deferred cache items.
   */
  public function commit(): Awaitable<bool>;
}
