namespace Nuxed\Cache;

interface ICache {
  /**
   * Determine if an item exists in the cache.
   */
  public function contains(string $key): Awaitable<bool>;

  /**
   * Fetches a value from the cache.
   */
  public function get(string $key, mixed $default = null): Awaitable<dynamic>;

  /**
   * Retrieve a value from the cache and delete it.
   */
  public function pull(string $key, mixed $default = null): Awaitable<dynamic>;

  /**
   * Store an item in the cache.
   */
  public function put(
    string $key,
    mixed $value,
    ?int $ttl = null,
  ): Awaitable<bool>;

  /**
   * Store an item in the cache if the key does not exist.
   */
  public function add(
    string $key,
    mixed $value,
    ?int $ttl = null,
  ): Awaitable<bool>;

  /**
   * Increment the value of an item in the cache.
   */
  public function increment(string $key, num $value = 1): Awaitable<bool>;

  /**
   * Decrement the value of an item in the cache.
   */
  public function decrement(string $key, num $value = 1): Awaitable<bool>;

  /**
   * Store an item in the cache indefinitely.
   */
  public function forever(string $key, mixed $value): Awaitable<bool>;

  /**
   * Get an item from the cache, or execute the given Closure and store the result.
   */
  public function remember<T>(
    string $key,
    (function(): Awaitable<T>) $callback,
    ?int $ttl = null,
  ): Awaitable<T>;

  /**
   * Get an item from the cache, or execute the given Closure and store the result forever.
   */
  public function sear<T>(
    string $key,
    (function(): Awaitable<T>) $callback,
  ): Awaitable<T>;

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $key, mixed $value, ?int $ttl = null): bool;

  /**
   * Persists any deferred cache items.
   */
  public function commit(): Awaitable<bool>;

  /**
   * Remove an item from the cache.
   */
  public function forget(string $key): Awaitable<bool>;

  /**
   * Wipes clean the entire cache's keys.
   */
  public function clear(): Awaitable<bool>;
}
