namespace Nuxed\Lib;

use type Nuxed\Contract\Lib\Stringable;
use type Throwable;

trait StringableTrait implements Stringable {
  abstract public function toString(): string;

  public function __toString(): string {
    try {
      return $this->toString();
    } catch (Throwable $e) {
      return '';
    }
  }
}
