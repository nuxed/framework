namespace Nuxed\Cache\Store;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Cache\_Private;

abstract class Store implements IStore {
  protected dict<string, string> $ids = dict[];
  protected dict<string, shape('value' => mixed, 'ttl' => ?int, ...)>
    $deferred = dict[];

  protected string $namespace = '';
  protected string $namespaceVersion = '';
  protected bool $versioningIsEnabled = true;
  protected ?int $maxIdLength = null;

  public function __construct(
    string $namespace = '',
    protected int $defaultTtl = 0,
  ) {
    if ('' !== $namespace) {
      _Private\validate_key($namespace);
      $this->namespace = $namespace.':';
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

    $deleted = await $this->doDelete($id);
    return $deleted || $def;
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
    if ($cleared = $this->versioningIsEnabled) {
      $namespaceVersion = Str\splice(
        \base64_encode(\pack('V', SecureRandom\int())),
        ':',
        5,
      );
      try {
        $cleared = await $this->store(
          '/'.$this->namespace,
          $namespaceVersion,
          0,
        );
      } catch (\Exception $e) {
        $cleared = false;
      }

      if ($cleared) {
        $this->namespaceVersion = $namespaceVersion;
        $this->ids = dict[];
      }
    }

    $result = await $this->doClear($this->namespace);
    return $result || $cleared;
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
    $wrappers = await Asio\vmkw(
      $this->deferred,
      ($key, $value) ==> {
        return $this->store($key, $value['value'], $value['ttl']);
      },
    );
    $ok = true;
    foreach ($wrappers as $wrapper) {
      $ok = $ok && $wrapper->getResult();
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
   * @return bool the previous state of versioning
   */
  public function enableVersioning(bool $enable = true): bool {
    $wasEnabled = $this->versioningIsEnabled;
    $this->versioningIsEnabled = $enable;
    $this->namespaceVersion = '';
    $this->ids = dict[];
    return $wasEnabled;
  }

  protected async function getId(string $key): Awaitable<string> {
    if ($this->versioningIsEnabled && '' === $this->namespaceVersion) {
      $this->ids = dict[];
      $this->namespaceVersion = '1/';
      try {
        $namespaceVersion = await $this->doGet('/'.$this->namespace);
        $this->namespaceVersion = $namespaceVersion as string;
        if ('1:' === $this->namespaceVersion) {
          $this->namespaceVersion = Str\splice(
            \base64_encode(\pack('V', \time())),
            ':',
            5,
          );
          await $this->doStore(
            '@'.$this->namespace,
            $this->namespaceVersion,
            0,
          );
        }
      } catch (\Throwable $e) {
      }
    }

    if (C\contains_key($this->ids, $key)) {
      return $this->namespace.$this->namespaceVersion.$this->ids[$key];
    }

    _Private\validate_key($key);
    $this->ids[$key] = $key;

    if (null === $this->maxIdLength) {
      return $this->namespace.$this->namespaceVersion.$key;
    }
    $id = $this->namespace.$this->namespaceVersion.$key;
    $max = $this->maxIdLength as int;
    if (Str\length($id) > $max) {
      // Use MD5 to favor speed over security, which is not an issue here
      $this->ids[$key] = $id = Str\splice(
        \base64_encode(\hash('md5', $key, true)),
        ':',
        -(Str\length($this->namespaceVersion) + 2),
      );
      $id = $this->namespace.$this->namespaceVersion.$id;
    }

    return $id;
  }
}
