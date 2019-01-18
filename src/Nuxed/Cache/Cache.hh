<?hh // strict

namespace Nuxed\Cache;

use namespace HH\Lib\Str;
use type Nuxed\Contract\Cache\CacheInterface;
use type Nuxed\Contract\Cache\CacheExceptionInterface;
use type Nuxed\Contract\Service\ResetInterface;
use type Nuxed\Contract\Cache\CacheExceptionInterface;
use type Nuxed\Contract\Cache\InvalidArgumentExceptionInterface;
use type Nuxed\Contract\Log\LoggerInterface;
use type Nuxed\Contract\Log\LoggerAwareInterface;
use type Nuxed\Contract\Log\LogLevel;
use type Nuxed\Contract\Log\NullLogger;
use type Exception;

class Cache implements CacheInterface, ResetInterface, LoggerAwareInterface {

  public function __construct(
    protected Store\StoreInterface $store,
    protected LoggerInterface $logger = new NullLogger(),
  ) {}

  public function setLogger(LoggerInterface $logger): void {
    $this->logger = $logger;
  }

  /**
   * Determine if an item exists in the cache.
   */
  public function contains(string $key): bool {
    return $this->box(() ==> $this->store->contains(static::validateKey($key)));
  }

  /**
   * Fetches a value from the cache.
   */
  public function get(string $key, mixed $default = null): mixed {
    return $this->box(
      () ==> $this->store->contains(static::validateKey($key))
        ? $this->store->get($key)
        : $default,
    );
  }

  /**
   * Retrieve a value from the cache and delete it.
   */
  public function pull(string $key, mixed $default = null): mixed {
    return $this->box(() ==> {
      if (!$this->store->contains(static::validateKey($key))) {
        return $default;
      }

      $value = $this->store->get($key);
      $this->store->delete($key);
      return $value;
    });
  }

  /**
   * Store an item in the cache.
   */
  public function put(string $key, mixed $value, ?int $ttl = null): bool {
    return $this->box(
      () ==> $this->store->store(static::validateKey($key), $value, $ttl),
    );
  }

  /**
   * Store an item in the cache if the key does not exist.
   */
  public function add(string $key, mixed $value, ?int $ttl = null): bool {
    return $this->box(() ==> {
      if ($this->store->contains(static::validateKey($key))) {
        return false;
      }

      return $this->store->store($key, $value, $ttl);
    });
  }

  /**
   * Increment the value of an item in the cache.
   */
  public function increment(string $key, num $value = 1): bool {
    $value = ($this->get(static::validateKey($key), 0) as num) + $value;
    return $this->put($key, $value);
  }

  /**
   * Decrement the value of an item in the cache.
   */
  public function decrement(string $key, num $value = 1): bool {
    return $this->increment($key, $value * -1);
  }

  /**
   * Store an item in the cache indefinitely.
   */
  public function forever(string $key, mixed $value): bool {
    return $this->box(
      () ==> $this->store->store(static::validateKey($key), $value, 0),
    );
  }

  /**
   * Get an item from the cache, or execute the given Closure and store the result.
   */
  public function remember(
    string $key,
    (function(): mixed) $callback,
    ?int $ttl = null,
  ): mixed {
    if ($this->contains(static::validateKey($key))) {
      return $this->get($key);
    }

    $value = $callback();
    $this->put($key, $value, $ttl);
    return $value;
  }

  /**
   * Get an item from the cache, or execute the given Closure and store the result forever.
   */
  public function sear(string $key, (function(): mixed) $callback): mixed {
    if ($this->contains(static::validateKey($key))) {
      return $this->get($key);
    }

    $value = $callback();
    $this->forever($key, $value);
    return $value;
  }

  /**
   * Remove an item from the cache.
   */
  public function forget(string $key): bool {
    return $this->box(() ==> $this->store->delete(static::validateKey($key)));
  }

  /**
   * Sets a cache item to be persisted later.
   */
  public function defer(string $key, mixed $value, ?int $ttl = null): bool {
    return $this->box(
      () ==> $this->store->defer(static::validateKey($key), $value, $ttl),
    );
  }

  /**
   * Persists any deferred cache items.
   */
  public function commit(): bool {
    return $this->box(() ==> $this->store->commit());
  }

  /**
   * Wipes clean the entire cache's keys.
   */
  public function clear(): bool {
    return $this->box(() ==> $this->store->clear());
  }

  public function reset(): void {
    if ($this->store is ResetInterface) {
      $this->store->reset();
    }
  }

  protected function box<T>((function(): T) $fun): T {
    try {
      return $fun();
    } catch (Exception $e) {

      $level = LogLevel::ALERT;
      if ($e is InvalidArgumentExceptionInterface) {
        $level = LogLevel::WARNING;
      }

      if (!$e is CacheExceptionInterface) {
        $e = new Exception\CacheException($e->getMessage(), $e->getCode(), $e);
      }

      $this->logger->log($level, 'Cache Exception : {message}', dict[
        'message' => $e->getMessage(),
        'exception' => $e,
      ]);

      throw $e;
    }
  }

  /**
   * Validates a cache key.
   *
   * @throws InvalidArgumentException When $key is not valid
   */
  public static function validateKey(string $key): string {
    if ('' === $key) {
      throw new Exception\InvalidArgumentException(
        'Cache key length must be greater than zero',
      );
    }
    if (false !== \strpbrk($key, '{}()/\@:')) {
      throw new Exception\InvalidArgumentException(
        Str\format(
          'Cache key "%s" contains reserved characters {}()/\@:',
          $key,
        ),
      );
    }
    return $key;
  }
}
