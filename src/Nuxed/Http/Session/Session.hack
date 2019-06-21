namespace Nuxed\Http\Session;

use namespace HH\Lib\C;

final class Session {
  const string SESSION_AGE_KEY = '__SESSION_AGE__';

  /**
   * Current data within the session.
   */
  private dict<string, mixed> $data;

  private bool $isRegenerated = false;

  private dict<string, mixed> $originalData;

  /**
   * Lifetime of the session cookie.
   */
  private int $age = 0;

  private bool $flushed = false;

  public function __construct(
    KeyedContainer<string, mixed> $data,
    private string $id = '',
  ) {
    $this->data = $this->originalData = dict($data);
    if (C\contains_key($data, Session::SESSION_AGE_KEY)) {
      $this->age = (int)$data[Session::SESSION_AGE_KEY];
    }
  }

  /**
   * Retrieve the session identifier.
   */
  public function getId(): string {
    return $this->id;
  }

  /**
   * Retrieve a value from the session.
   *
   * @param dynamic $default Default value to return if $name does not exist.
   */
  public function get(string $name, mixed $default = null): dynamic {
    if ($this->contains($name)) {
      return $this->data[$name];
    } else {
      return $default;
    }
  }

  /**
   * Whether or not the container has the given key.
   */
  public function contains(string $name): bool {
    return C\contains_key($this->data, $name);
  }

  /**
   * Store a value in the session.
   *
   * Values MUST be serializable in any format; we recommend ensuring the
   * values are JSON serializable for greatest portability.
   */
  public function put(string $name, mixed $value): void {
    $this->data[$name] = $value;
  }

  /**
   * Store a value in the session if the key does not exist.
   */
  public function add(string $name, mixed $value): void {
    if (!$this->contains($name)) {
      $this->put($name, $value);
    }
  }

  /**
   * Increment the value of an item in the session.
   */
  public function increment(string $key, num $value = 1): void {
    $this->put($key, $this->get($key, 0) as num + $value);
  }

  /**
   * Decrement the value of an item in the session.
   */
  public function decrement(string $key, num $value = 1): void {
    $this->put($key, $this->get($key, 0) as num - $value);
  }

  /**
   * Remove a value from the session.
   */
  public function forget(string $name): void {
    unset($this->data[$name]);
  }

  /**
   * Clear all values.
   */
  public function clear(): void {
    $this->data = dict[];
  }

  /**
   * Deletes the current session data from the session and
   * deletes the session cookie. This is used if you want to ensure
   * that the previous session data can't be accessed again from the
   * user's browser.
   */
  public function flush(): void {
    $this->clear();
    $this->flushed = true;
  }

  public function flushed(): bool {
    return $this->flushed;
  }

  /**
   * Does the session contain changes? If not, the middleware handling
   * session persistence may not need to do more work.
   */
  public function changed(): bool {
    if ($this->regenerated()) {
      return true;
    }

    return $this->data !== $this->originalData;
  }

  /**
   * Regenerate the session.
   *
   * This can be done to prevent session fixation. When executed, it SHOULD
   * return a new instance; that instance should always return true for
   * isRegenerated().
   */
  public function regenerate(): this {
    $session = clone $this;
    $session->isRegenerated = true;
    return $session;
  }

  /**
   * Method to determine if the session was regenerated; should return
   * true if the instance was produced via regenerate().
   */
  public function regenerated(): bool {
    return $this->isRegenerated;
  }

  /**
   * Sets the expiration time for the session.
   *
   * The session will expire after that many seconds
   * of inactivity.
   *
   * for example, calling
   * <code>
   *     $session->exipre(300);
   * </code>
   * would make the session expire in 5 minutes of inactivity.
   */
  public function expire(int $duration): void {
    $this->put(Session::SESSION_AGE_KEY, $duration);
    $this->age = $duration;
  }

  /*
   * Determine how long the session cookie should live.
   *
   * Generally, this will return the value provided to exipre().
   *
   * If that method has not been called, the value can return one of the
   * following:
   *
   * - 0 or a negative value, to indicate the cookie should be treated as a
   *   session cookie, and expire when the window is closed. This should be
   *   the default behavior.
   * - If expire() was provided during session creation or anytime later,
   *   the persistence engine should pull the TTL value from the session itself
   *   and return it here.
   */
  public function age(): int {
    return $this->age;
  }

  public function items(): KeyedContainer<string, dynamic> {
    /* HH_IGNORE_ERROR[4110] */
    return $this->data;
  }
}
