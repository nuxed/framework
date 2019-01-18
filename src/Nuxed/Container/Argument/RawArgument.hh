<?hh // strict

namespace Nuxed\Container\Argument;

class RawArgument implements RawArgumentInterface {
  public function __construct(protected mixed $value) {}

  public function getValue(): mixed {
    return $this->value;
  }
}
