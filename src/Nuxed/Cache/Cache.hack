namespace Nuxed\Cache;

use namespace HH\Asio;
use type Nuxed\Log\ILogger;
use type Nuxed\Log\ILoggerAware;
use type Nuxed\Log\LogLevel;
use type Nuxed\Log\NullLogger;
use type Exception;

final class Cache implements ICache, ILoggerAware {
  public function __construct(
    protected Store\IStore $store,
    protected ILogger $logger = new NullLogger(),
  ) {}

  public function setLogger(ILogger $logger): void {
    $this->logger = $logger;
  }

  /**
   * Determine if an item exists in the cache.
   */
  public function contains(string $key): Awaitable<bool> {
    return $this->box(
      () ==> {
        _Private\validate_key($key);
        return $this->store->contains($key);
      },
    );
  }

  /**
   * Fetches a value from the cache.
   */
  public function get(string $key, mixed $default = null): Awaitable<dynamic> {
    return $this->box(async () ==> {
      _Private\validate_key($key);
      $exist = await $this->store->contains($key);
      if ($exist) {
        return await $this->store->get($key);
      } else {
        /* HH_IGNORE_ERROR[4110] mixed <-> dynamic */
        return $default;
      }
    });
  }

  /**
   * Retrieve a value from the cache and delete it.
   */
  public function pull(string $key, mixed $default = null): Awaitable<dynamic> {
    return $this->box(async () ==> {
      $exist = await $this->contains($key);
      if (!$exist) {
        /* HH_IGNORE_ERROR[4110] mixed <-> dynamic */
        return $default;
      }

      $value = await $this->get($key);
      await $this->forget($key);
      return $value;
    });
  }

  /**
   * Store an item in the cache.
   */
  public function put(
    string $key,
    mixed $value,
    ?int $ttl = null,
  ): Awaitable<bool> {
    return $this->box(
      () ==> {
        _Private\validate_key($key);
        return $this->store->store($key, $value, $ttl);
      },
    );
  }

  /**
   * Store an item in the cache if the key does not exist.
   */
  public function add(
    string $key,
    mixed $value,
    ?int $ttl = null,
  ): Awaitable<bool> {
    return $this->box(async () ==> {
      $exist = await $this->contains($key);
      if ($exist) {
        return false;
      }

      return await $this->put($key, $value, $ttl);
    });
  }

  /**
   * Increment the value of an item in the cache.
   */
  public async function increment(
    string $key,
    num $value = 1,
  ): Awaitable<bool> {
    $val = await $this->get($key, 0);
    $val = ($val as num) + $value;
    return await $this->put($key, $val);
  }

  /**
   * Decrement the value of an item in the cache.
   */
  public function decrement(string $key, num $value = 1): Awaitable<bool> {
    return $this->increment($key, $value * -1);
  }

  /**
   * Store an item in the cache indefinitely.
   */
  public function forever(string $key, mixed $value): Awaitable<bool> {
    return $this->box(() ==> $this->put($key, $value, 0));
  }

  /**
   * Get an item from the cache, or execute the given Closure and store the result.
   */
  public async function remember<T>(
    string $key,
    (function(): Awaitable<T>) $callback,
    ?int $ttl = null,
  ): Awaitable<T> {
    if (await $this->contains($key)) {
      /* HH_IGNORE_ERROR[4110] */
      return await $this->get($key);
    }

    $value = await $callback();
    await $this->put($key, $value, $ttl);
    return $value;
  }

  /**
   * Get an item from the cache, or execute the given Closure and store the result forever.
   */
  public async function sear<T>(
    string $key,
    (function(): Awaitable<T>) $callback,
  ): Awaitable<T> {
    if (await $this->contains($key)) {
      /* HH_IGNORE_ERROR[4110] */
      return await $this->get($key);
    }

    $value = await $callback();
    await $this->forever($key, $value);
    return $value;
  }

  /**
   * Remove an item from the cache.
   */
  public function forget(string $key): Awaitable<bool> {
    return $this->box(() ==> {
      _Private\validate_key($key);
      return $this->store->delete($key);
    });
  }

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $key, mixed $value, ?int $ttl = null): bool {
    return Asio\join(
      $this->box(
        async () ==> {
          _Private\validate_key($key);
          return $this->store->defer($key, $value, $ttl);
        },
      ),
    );
  }

  /**
   * Persists any deferred cache items.
   */
  public function commit(): Awaitable<bool> {
    return $this->box(() ==> $this->store->commit());
  }

  /**
   * Wipes clean the entire cache's keys.
   */
  public function clear(): Awaitable<bool> {
    return $this->box(() ==> $this->store->clear());
  }

  protected async function box<T>(
    (function(): Awaitable<T>) $fun,
  ): Awaitable<T> {
    try {
      return await $fun();
    } catch (Exception $e) {

      $level = LogLevel::ALERT;
      if ($e is Exception\InvalidArgumentException) {
        $level = LogLevel::WARNING;
      }

      if (!$e is Exception\IException) {
        $e = new Exception\CacheException($e->getMessage(), $e->getCode(), $e);
      }

      $this->logger->log($level, 'Cache Exception : {message}', dict[
        'message' => $e->getMessage(),
        'exception' => $e,
      ]);

      throw $e;
    }
  }
}
