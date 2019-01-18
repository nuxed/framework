<?hh // strict

namespace Nuxed\Contract\Http\Session;


interface SessionInterface {
  /**
   * Retrieve the session identifier.
   */
  public function getId(): string;

  /**
   * Retrieve a value from the session.
   *
   * @param mixed $default Default value to return if $name does not exist.
   */
  public function get(string $name, mixed $default = null): mixed;

  /**
   * Whether or not the container has the given key.
   */
  public function contains(string $name): bool;

  /**
   * Set a value within the session.
   *
   * Values MUST be serializable in any format; we recommend ensuring the
   * values are JSON serializable for greatest portability.
   */
  public function set(string $name, mixed $value): void;

  /**
   * Remove a value from the session.
   */
  public function remove(string $name): void;

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
  public function expire(int $duration): void;

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
  public function age(): int;

  /**
   * Clear all values.
   */
  public function clear(): void;

  /**
   * Deletes the current session data from the session and
   * deletes the session cookie. This is used if you want to ensure
   * that the previous session data can't be accessed again from the
   * user's browser.
   */
  public function flush(): void;

  /**
   * Regenerate the session.
   *
   * This can be done to prevent session fixation. When executed, it SHOULD
   * return a new instance; that instance should always return true for
   * isRegenerated().
   *
   * An example of where this WOULD NOT return a new instance is within the
   * shipped LazySession, where instead it would return itself, after
   * internally re-setting the proxied session.
   */
  public function regenerate(): SessionInterface;

  /**
   * Does the session contain changes? If not, the middleware handling
   * session persistence may not need to do more work.
   */
  public function changed(): bool;

  /**
   * Method to determine if the session was regenerated; should return
   * true if the instance was produced via regenerate().
   */
  public function regenerated(): bool;

  /**
   * Method to determine if the session was flushed; should return
   * true if flush() was called.
   */
  public function flushed(): bool;

  /**
   * Get the session items; this method is used
   * to get the session data for storage.
   */
  public function items(): KeyedContainer<string, mixed>;
}
