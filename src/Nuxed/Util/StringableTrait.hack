namespace Nuxed\Util;

trait StringableTrait implements Stringable, \Stringish {
  abstract public function toString(): string;

  public function __toString(): string {
    try {
      return $this->toString();
    } catch (\Throwable $e) {
      return '';
    }
  }
}
