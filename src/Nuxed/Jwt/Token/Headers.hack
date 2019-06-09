namespace Nuxed\Jwt\Token;

use namespace HH\Lib\C;
use namespace Nuxed\Util;

final class Headers {
  use Util\StringableTrait;

  private dict<string, dynamic> $data = dict[];

  public function __construct(
    KeyedContainer<string, mixed> $data,
    private string $encoded,
  ) {
    foreach ($data as $key => $value) {
      $this->data[$key] = $value as dynamic;
    }
  }

  public function contains(string $header): bool {
    return C\contains_key($this->data, $header);
  }

  public function get(string $header, mixed $default = null): dynamic {
    return $this->data[$header] ?? $default;
  }

  public function toString(): string {
    return $this->encoded;
  }
}
