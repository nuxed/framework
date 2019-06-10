namespace Nuxed\Jwt\Token;

use namespace Nuxed\Util;

final class Signature {
  use Util\StringableTrait;

  public function __construct(private string $hash, private string $encoded) {}

  public function getHash(): string {
    return $this->hash;
  }

  public function toString(): string {
    return $this->encoded;
  }
}
