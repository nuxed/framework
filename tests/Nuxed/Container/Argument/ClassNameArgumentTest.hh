<?hh // strict

namespace Nuxed\Test\Container\Argument;

use type Nuxed\Container\Argument\ClassNameArgument;
use function Facebook\FBExpect\expect;
use type Facebook\HackTest\HackTest;

class ClassNameArgumentTest extends HackTest {
  /**
   * Asserts that a raw argument object can set and get a value.
   */
  public function testClassNameSetsAndGetsArgument(): void {
    $arguments = vec[
      'string',
      'string2',
    ];
    foreach ($arguments as $expected) {
      $argument = new ClassNameArgument($expected);
      expect($argument->getValue())->toBeSame($expected);
    }
  }
}
