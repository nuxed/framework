namespace Nuxed\Cache\Store;

class NullStore implements IStore {
  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  public async function store(
    string $_id,
    mixed $_value,
    ?int $_ttl = null,
  ): Awaitable<bool> {
    return false;
  }

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $_id, mixed $_value, ?int $_ttl = null): bool {
    return false;
  }

  /**
   * Determines whether an item is present in the cache.
   */
  public async function contains(string $_id): Awaitable<bool> {
    return false;
  }

  /**
   * Delete an item from the cache by its unique key.
   */
  public async function delete(string $_id): Awaitable<bool> {
    return false;
  }

  /**
   * Fetches a value from the cache.
   */
  public async function get(string $_id): Awaitable<mixed> {
    return null;
  }

  /**
   * Wipes clean the entire cache's keys.
   */
  public async function clear(): Awaitable<bool> {
    return false;
  }

  /**
   * Persists any deferred cache items.
   */
  public async function commit(): Awaitable<bool> {
    return false;
  }
}
