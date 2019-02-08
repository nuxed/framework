<?hh // strict

namespace Nuxed\Io;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use type Nuxed\Util\StringableTrait;
use type Vector;
use type Iterator;
use type Countable;
use type IteratorAggregate;

final class Lines implements Countable, IteratorAggregate<string> {
  use StringableTrait;

  public function __construct(private vec<string> $lines) {
  }

  public function count(): int {
    return C\count($this->lines);
  }

  public function first(): string {
    return C\firstx($this->lines);
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
