namespace Nuxed\Http\Flash;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace Nuxed\Http\Session;
use namespace Facebook\TypeAssert;

final class FlashMessages {
  const string FLASH_NEXT = self::class.'::FLASH_NEXT';

  const type TMessages = KeyedContainer<string, shape(
    'value' => dynamic,
    'hops' => int,
    ...
  )>;

  private dict<string, dynamic> $current = dict[];

  public function __construct(
    private Session\Session $session,
    private string $key,
  ) {
    $this->prepare();
  }

  /**
   * Create an instance from a session container.
   */
  public static function create(
    Session\Session $session,
    string $sessionKey = self::FLASH_NEXT,
  ): this {
    return new FlashMessages($session, $sessionKey);
  }

  /**
   * Set a flash value with the given key.
   */
  public function flash(string $name, dynamic $value, int $hops = 1): void {
    if ($hops < 1) {
      throw new Exception\InvalidHopsValueException(Str\format(
        'Hops value specified for flash message "%s" was too low; must be greater than 0, received %d',
        $name,
        $hops,
      ));
    }

    $messages = dict($this->messages());
    $messages[$name] = shape(
      'value' => $value,
      'hops' => $hops,
    );
    $this->session->put($this->key, $messages);
  }

  /**
   * Set a flash value with the given key, but allow access during this request.
   */
  public function now(string $name, dynamic $value, int $hops = 1): void {
    $this->current[$name] = $value;
    $this->flash($name, $value, $hops);
  }

  /**
  * Retrieve a flash value.
  */
  public function get(string $name, ?dynamic $default = null): dynamic {
    return $this->current[$name] ?? $default;
  }

  /**
   * Retrieve all flash items.
   */
  public function items(): KeyedContainer<string, dynamic> {
    return $this->current;
  }

  /**
   * Clear all flash values.
   */
  public function clear(): void {
    $this->session->forget($this->key);
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

    $messages = dict($this->messages());
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
      $this->session->forget($this->key);
    } else {
      $this->session->put($this->key, $messages);
    }

    $this->current = $current;
  }

  private function messages(): this::TMessages {
    return TypeAssert\matches_type_structure(
      type_structure($this, 'TMessages'),
      $this->session->get($this->key, dict[]),
    );
  }
}
