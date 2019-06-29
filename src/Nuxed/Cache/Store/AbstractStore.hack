namespace Nuxed\Cache\Store;

use namespace HH\Asio;
use namespace HH\Lib\{C, Str};
use namespace Nuxed\Cache\_Private;

abstract class AbstractStore implements IStore {
  protected dict<string, string> $ids = dict[];
  protected dict<string, shape('value' => mixed, 'ttl' => ?int, ...)>
    $deferred = dict[];

  protected ?int $maxIdLength = null;

  public function __construct(
    protected string $namespace = '',
    protected int $defaultTtl = 0,
  ) {
    if ('' !== $namespace) {
      _Private\validate_key($namespace);
    }
  }

  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  abstract protected function doStore(
    string $id,
    dynamic $value,
    int $ttl,
  ): Awaitable<bool>;

  /**
   * Determines whether an item is present in the cache.
   */
  abstract protected function doContains(string $id): Awaitable<bool>;

  /**
   * Delete an item from the cache by its unique key.
   */
  abstract protected function doDelete(string $id): Awaitable<bool>;

  /**
   * Fetches a value from the cache.
   */
  abstract protected function doGet(string $id): Awaitable<dynamic>;

  /**
   * Wipes clean the entire cache's keys.
   */
  abstract protected function doClear(string $namespace): Awaitable<bool>;

  /**
   * Persists data in the cache, uniquely referenced by a key with an optional expiration TTL time.
   */
  public async function store<T>(
    string $id,
    T $value,
    ?int $ttl = null,
  ): Awaitable<bool> {
    $id = await $this->getId($id);
    $ttl = $ttl ?? $this->defaultTtl;
    return await $this->doStore($id, $value, $ttl);
  }

  /**
   * Determines whether an item is present in the cache.
   */
  public async function contains(string $key): Awaitable<bool> {
    $id = await $this->getId($key);

    if (C\contains_key($this->deferred, $key)) {
      await $this->commit();
    }

    return await $this->doContains($id);
  }

  /**
   * Delete an item from the cache by its unique key.
   */
  public async function delete(string $key): Awaitable<bool> {
    $id = await $this->getId($key);
    $def = false;
    if (C\contains_key($this->deferred, $key)) {
      unset($this->deferred[$key]);
      $def = true;
    }

    if (!await $this->doContains($id)) {
      return $def;
    }

    return await $this->doDelete($id) || $def;
  }

  /**
   * Fetches a value from the cache.
   */
  public async function get(string $key): Awaitable<dynamic> {
    if (0 !== C\count($this->deferred)) {
      await $this->commit();
    }

    $id = await $this->getId($key);
    return await $this->doGet($id);
  }

  public async function clear(): Awaitable<bool> {
    $this->deferred = dict[];
    return await $this->doClear($this->namespace);
  }

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $id, mixed $value, ?int $ttl = null): bool {
    $this->deferred[$id] = shape(
      'value' => $value,
      'ttl' => $ttl,
    );
    return true;
  }

  /**
   * Persists any deferred cache items.
   */
  public async function commit(): Awaitable<bool> {
    return C\reduce(
      await Asio\mmk(
        $this->deferred,
        ($key, $value) ==> {
          return $this->store($key, $value['value'], $value['ttl']);
        },
      ),
      ($ok, $c) ==> $ok && $c,
      true,
    );
  }

  final protected async function getId(string $key): Awaitable<string> {
    if (C\contains_key($this->ids, $key)) {
      return $this->namespace.$this->ids[$key];
    }

    _Private\validate_key($key);
    $this->ids[$key] = $key;

    if ($this->maxIdLength is null) {
      return $this->namespace.$key;
    }
    $id = $this->namespace.$key;
    $max = $this->maxIdLength ;
    if (Str\length($id) > $max) {
      // Use MD5 to favor speed over security, which is not an issue here
      $this->ids[$key] = $id = Str\splice(
        \base64_encode(\hash('md5', $key, true)),
        ':',
        -2,
      );
      $id = $this->namespace.$id;
    }

    return $id;
  }
}
