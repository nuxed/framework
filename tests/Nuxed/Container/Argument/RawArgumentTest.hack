namespace Nuxed\Test\Container\Argument;

use type Facebook\HackTest\HackTest;
use type Nuxed\Container\Argument\RawArgument;
use function Facebook\FBExpect\expect;

class RawArgumentTest extends HackTest {
  /**
   * Asserts that a raw argument object can set and get a value.
   */
  public function testRawArgumentSetsAndGetsArgument(): void {
    $arguments = [
      'string',
      Vector {},
      vec[],
      Map {},
      Set {},
      dict[],
      [],
      varray[],
      darray[],
      function(): void {},
      (): int ==> 1,
      true,
      1,
      1.23,
      false,
      expect(false),
    ];

    foreach ($arguments as $expected) {
      $argument = new RawArgument($expected);
      expect($argument->getValue())->toBeSame($expected);
    }
  }
}
