namespace Nuxed\Test\Container\Inflector;

use namespace HH\Lib\C;
use type Facebook\HackTest\HackTest;
use type Nuxed\Container\Inflector\Inflector;
use type Nuxed\Container\Container;
use type Nuxed\Test\Container\Asset\Bar;
use type Nuxed\Test\Container\Asset\Baz;
use type Nuxed\Test\Container\Asset\Foo;
use type ReflectionClass;
use function Facebook\FBExpect\expect;

class InflectorTest extends HackTest {
  /**
   * Asserts that the inflector sets expected method calls.
   */
  public function testInflectorSetsExpectedMethodCalls(): void {
    $container = new Container();
    $inflector = (new Inflector('Type'))->setContainer($container);

    $inflector->invokeMethod('method1', vec['arg1']);

    $inflector->invokeMethods(dict[
      'method2' => vec['arg1'],
      'method3' => vec['arg1'],
    ]);

    $methods = (new ReflectionClass($inflector))->getProperty('methods');
    $methods->setAccessible(true);

    $methods = $methods->getValue($inflector);

    expect($methods[0][0])->toBeSame('method1');
    expect($methods[1][0])->toBeSame('method2');
    expect($methods[2][0])->toBeSame('method3');

    expect($methods[0][1])->toBeSame(vec['arg1']);
    expect($methods[1][1])->toBeSame(vec['arg1']);
    expect($methods[2][1])->toBeSame(vec['arg1']);
  }

  /**
   * Asserts that the inflector sets expected properties.
   */
  public function testInflectorSetsExpectedProperties(): void {
    $container = new Container();
    $inflector = (new Inflector('Type'))->setContainer($container);

    $inflector->setProperty('property1', 'value');

    $inflector->setProperties(dict[
      'property2' => 'value',
      'property3' => 'value',
    ]);

    $properties = (new \ReflectionClass($inflector))->getProperty('properties');
    $properties->setAccessible(true);

    $dict = $properties->getValue($inflector);

    expect(C\contains_key($dict, 'property1'))->toBeTrue();
    expect(C\contains_key($dict, 'property2'))->toBeTrue();
    expect(C\contains_key($dict, 'property3'))->toBeTrue();

    expect($dict['property1'])->toBeSame('value');
    expect($dict['property2'])->toBeSame('value');
    expect($dict['property3'])->toBeSame('value');
  }

  /**
   * Asserts that the inflector will inflect on an object with properties.
   */
  public function testInflectorInflectsWithProperties(): void {
    $bar = new Bar();

    $container = new Container();
    $container->add(Bar::class, (): Bar ==> $bar);

    $inflector = (new Inflector('Type'))
      ->setContainer($container)
      ->setProperty('bar', Bar::class);

    $baz = new Baz();

    $inflector->inflect($baz);

    expect($baz->bar)->toBeInstanceOf(Bar::class);
    expect($baz->bar)->toBeSame($bar);
  }

  /**
   * Asserts that the inflector will inflect on an object with method call.
   */
  public function testInflectorInflectsWithMethodCall(): void {
    $container = new Container();

    $bar = new Bar();

    $container->add(Bar::class, (): Bar ==> $bar);

    $inflector = (new Inflector('Type'))
      ->setContainer($container)
      ->invokeMethod('setBar', vec[
        Bar::class,
      ]);

    $foo = new Foo(null);

    $inflector->inflect($foo);

    expect($foo->bar)->toBeInstanceOf(Bar::class);
    expect($foo->bar)->toBeSame($bar);
  }

  /**
   * Asserts that the inflector will inflect on an object with a callback.
   */
  public function testInflectorInflectsWithCallback(): void {

    $bar = new Bar();
    $inflector = new Inflector('Type', (mixed $object): void ==> {
      /* HH_IGNORE_ERROR[4064] x */
      $object->setBar($bar);
    });

    $foo = new Foo(null);
    $inflector->inflect($foo);

    expect($foo->bar)->toBeSame($bar);
  }
}
