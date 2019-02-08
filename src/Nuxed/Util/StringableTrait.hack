namespace Nuxed\Util;

use type Nuxed\Contract\Util\Stringable;
use type Throwable;
use type Stringish;

trait StringableTrait implements Stringable, Stringish {
  abstract public function toString(): string;

  public function __toString(): string {
    try {
      return $this->toString();
    } catch (Throwable $e) {
      return '';
    }
  }
}
