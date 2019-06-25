namespace Nuxed\Io;

use namespace HH\Lib\{C, Str, Vec};
use type HH\InvariantException;
use type Nuxed\Util\StringableTrait;
use type Iterator;
use type Countable;
use type IteratorAggregate;

final class Lines implements Countable, IteratorAggregate<string> {
  use StringableTrait;

  public function __construct(private Container<string> $lines) {
  }

  public function count(): int {
    return C\count($this->lines);
  }

  public function first(): string {
    try {
      return C\firstx($this->lines);
    } catch (InvariantException $e) {
      throw new Exception\OutOfRangeException(
        'Lines instance is empty.',
        $e->getCode(),
        $e,
      );
    }
  }

  /**
   * @return tuple(string, Lines)   a tuple of the first line and the rest of
   *                                the lines as a new Lines instance.
   */
  public function jump(): (string, Lines) {
    return tuple($this->first(), new self(Vec\drop($this->lines, 1)));
  }

  public static function blank(string $line): bool {
    return Str\trim($line, " \t") === '';
  }

  public function getIterator(): Iterator<string> {
    return (new Vector($this->lines))->getIterator();
  }

  public function toString(): string {
    return Str\join($this->lines, "\n");
  }
}
