<?hh // strict

namespace Nuxed\Test\Container\Asset;

class Foo {
  public ?Bar $bar;
  public static ?Bar $staticBar;
  public static ?string $staticHello;

  public function __construct(?Bar $bar) {
    $this->bar = $bar;
  }

  public function setBar(Bar $bar): void {
    $this->bar = $bar;
  }

  public static function staticSetBar(
    Bar $bar,
    string $hello = 'hello world',
  ): void {
    self::$staticBar = $bar;
    self::$staticHello = $hello;
  }
}
