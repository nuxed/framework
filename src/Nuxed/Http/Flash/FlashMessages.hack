namespace Nuxed\Http\Flash;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use type Nuxed\Contract\Http\Flash\FlashMessagesInterface;
use type Nuxed\Contract\Http\Session\SessionInterface;

class FlashMessages implements FlashMessagesInterface {
  private dict<string, mixed> $current = dict[];

  public function __construct(
    private SessionInterface $session,
    private string $key,
  ) {
    $this->prepare();
  }

  /**
   * Create an instance from a session container.
   */
  public static function create(
    SessionInterface $session,
    string $sessionKey = self::FLASH_NEXT,
  ): FlashMessagesInterface {
    return new FlashMessages($session, $sessionKey);
  }

  /**
   * Set a flash value with the given key.
   */
  public function flash(string $name, mixed $value, int $hops = 1): void {
    if ($hops < 1) {
      throw new Exception\InvalidHopsValueException(Str\format(
        'Hops value specified for flash message "%s" was too low; must be greater than 0, received %d',
        $name,
        $hops,
      ));
    }

    $messages = $this->messages();
    $messages[$name] = dict[
      'value' => $value,
      'hops' => $hops,
    ];
    $this->session->set($this->key, $messages);
  }

  /**
   * Set a flash value with the given key, but allow access during this request.
   */
  public function now(string $name, mixed $value, int $hops = 1): void {
    $this->current[$name] = $value;
    $this->flash($name, $value, $hops);
  }

  /**
  * Retrieve a flash value.
  */
  public function get(string $name, mixed $default = null): mixed {
    return $this->current[$name] ?? $default;
  }

  /**
   * Retrieve all flash values.
   */
  public function all(): KeyedContainer<string, mixed> {
    return $this->current;
  }

  /**
   * Clear all flash values.
   */
  public function clear(): void {
    $this->session->remove($this->key);
  }

  /**
   * Prolongs any current flash messages for one more hop.
   */
  public function prolong(): void {
    $messages = $this->messages();
    foreach ($this->current as $key => $value) {
      if (C\contains_key($messages, $key)) {
        continue;
      }

      $this->flash($key, $value);
    }
  }

  private function prepare(): void {
    if (!$this->session->contains($this->key)) {
      return;
    }

    $messages = $this->messages();
    $current = dict[];
    foreach ($messages as $key => $data) {
      $current[$key] = $data['value'];

      if ($data['hops'] === 1) {
        unset($messages[$key]);
        continue;
      }

      $data['hops'] = ((int)$data['hops']) - 1;
      $messages[$key] = $data;
    }

    if (C\is_empty($messages)) {
      $this->session->remove($this->key);
    } else {
      $this->session->set($this->key, $messages);
    }

    $this->current = $current;
  }

  private function messages(): dict<string, dict<string, arraykey>> {
    // UNSAFE
    return $this->session->get($this->key, dict[]);
  }
}
