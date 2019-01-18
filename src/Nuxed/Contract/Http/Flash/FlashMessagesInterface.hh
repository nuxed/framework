<?hh // strict

namespace Nuxed\Contract\Http\Flash;

use type Nuxed\Contract\Http\Session\SessionInterface;

interface FlashMessagesInterface {

  const string FLASH_NEXT = self::class.'::FLASH_NEXT';

  /**
   * Create an instance from a session container.
   *
   * Flash messages will be retrieved from and persisted to the session via
   * the `$sessionKey`.
   */
  public static function create(
    SessionInterface $session,
    string $sessionKey = self::FLASH_NEXT,
  ): FlashMessagesInterface;

  /**
   * Set a flash value with the given key.
   *
   * Flash values are accessible on the next "hop", where a hop is the next
   * time the session is accessed; you may pass an additional hops integer to allow
   * access for more than one hope.
   */
  public function flash(string $name, mixed $value, int $hops = 1): void;

  /**
   * Set a flash value with the given key, but allow access during this request.
   *
   *
   * Flash values are generally accessible only on subsequent requests;
   * using this method, may make the value available during the current
   * request as well.
   */
  public function now(string $name, mixed $value, int $hops = 1): void;


  /**
  * Retrieve a flash value.
  *
  * Will return a value only if flash value was set in a previous request,
  * or if `now()` was called in the request with
  * the same `$name`.
  *
  * @param mixed $default Default value to return if $name does not exist.
  */
  public function get(string $name, mixed $default = null): mixed;

  /**
   * Retrieve all flash values.
   *
   * Will return all values was set in a previous request, or if `now()`
   * was called in this request.
   */
  public function all(): KeyedContainer<string, mixed>;

  /**
   * Clear all flash values.
   *
   * Affects the next and subsequent requests.
   */
  public function clear(): void;

  /**
   * Prolongs any current flash messages for one more hop.
   */
  public function prolong(): void;
}
