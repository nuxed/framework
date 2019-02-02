namespace Nuxed\Test\Container;

use type Nuxed\Container\Exception\NotFoundException;
use type Nuxed\Container\ReflectionContainer;
use type Nuxed\Container\Container;
use type Nuxed\Test\Container\Asset\{Foo, FooCallable, Bar};
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class ReflectionContainerTest extends HackTest {
  /**
   * Asserts that ReflectionContainer claims it has an item if a class exists for the alias.
   */
  public function testHasReturnsTrueIfClassExists(): void {
    $container = new ReflectionContainer();
    expect($container->has(ReflectionContainer::class))->toBeTrue();
  }

  /**
   * Asserts that ReflectionContainer denies it has an item if a class does not exist for the alias.
   */
  public function testHasReturnsFalseIfClassDoesNotExist(): void {
    $container = new ReflectionContainer();
    expect($container->has('blah'))->toBeFalse();
  }

  /**
   * Asserts that ReflectionContainer instantiates a class that does not have a constructor.
   */
  public function testContainerInstantiatesClassWithoutConstructor(): void {
    $classWithoutConstructor = \stdClass::class;
    $container = new ReflectionContainer();
    expect($container->get($classWithoutConstructor))->toBeInstanceOf(
      $classWithoutConstructor,
    );
  }

  /**
   * Asserts that ReflectionContainer instantiates and cacheds a class that does not have a constructor.
   */
  public function testContainerInstantiatesAndCachesClassWithoutConstructor(
  ): void {
    $classWithoutConstructor = \stdClass::class;
    $container = (new ReflectionContainer())->cacheResolutions();
    $classWithoutConstructorOne = $container->get($classWithoutConstructor);
    $classWithoutConstructorTwo = $container->get($classWithoutConstructor);
    expect($classWithoutConstructorOne)->toBeInstanceOf(
      $classWithoutConstructor,
    );
    expect($classWithoutConstructorTwo)->toBeInstanceOf(
      $classWithoutConstructor,
    );
    expect($classWithoutConstructorTwo)->toBeSame($classWithoutConstructorOne);
  }

  /**
   * Asserts that ReflectionContainer instantiates a class that has a constructor.
   */
  public function testGetInstantiatesClassWithConstructor(): void {
    $classWithConstructor = Foo::class;
    $dependencyClass = Bar::class;
    $container = new ReflectionContainer();
    $container->setContainer($container);
    $item = $container->get($classWithConstructor);
    expect($item)->toBeInstanceOf($classWithConstructor);
    $item as Foo;
    expect($item->bar)->toBeInstanceOf($dependencyClass);
  }

  /**
   * Asserts that ReflectionContainer instantiates and caches a class that has a constructor.
   */
  public function testGetInstantiatesAndCachedClassWithConstructor(): void {
    $classWithConstructor = Foo::class;
    $dependencyClass = Bar::class;
    $container = (new ReflectionContainer())->cacheResolutions();
    $container->setContainer($container);
    $itemOne = $container->get($classWithConstructor);
    $itemTwo = $container->get($classWithConstructor);
    expect($itemOne)->toBeInstanceOf($classWithConstructor);
    $itemOne as Foo;
    expect($itemOne->bar)->toBeInstanceOf($dependencyClass);
    expect($itemTwo)->toBeInstanceOf($classWithConstructor);
    $itemTwo as Foo;
    expect($itemTwo->bar)->toBeInstanceOf($dependencyClass);
    expect($itemTwo)->toBeSame($itemOne);
    expect($itemTwo->bar)->toBeSame($itemOne->bar);
  }

  /**
   * Asserts that ReflectionContainer instantiates a class that has a constructor with a type-hinted argument, and
   * fetches that dependency from the container injected into the ReflectionContainer.
   */
  public function testGetInstantiatesClassWithConstructorAndUsesContainer(
  ): void {
    $classWithConstructor = Foo::class;
    $dependencyClass = Bar::class;
    $dependency = new Bar();
    $container = new ReflectionContainer();
    $innerContainer = new Container();
    $innerContainer->add($dependencyClass, () ==> $dependency);
    $container->setContainer($innerContainer);
    $item = $container->get($classWithConstructor);
    expect($item)->toBeInstanceOf($classWithConstructor);
    $item as Foo;
    expect($item->bar)->toBeSame($dependency);
  }

  /**
   * Asserts that ReflectionContainer instantiates a class that has a constructor with a type-hinted argument, and
   * uses the values provided in the argument array.
   */
  public function testGetInstantiatesClassWithConstructorAndUsesArguments(
  ): void {
    $classWithConstructor = Foo::class;
    $dependencyClass = Bar::class;
    $dependency = new Bar();
    $container = new ReflectionContainer();
    $innerContainer = new Container();
    $innerContainer->add($dependencyClass, () ==> $dependency);
    $container->setContainer($innerContainer);
    $item = $container->get($classWithConstructor);
    expect($item)->toBeInstanceOf($classWithConstructor);
    $item as Foo;
    expect($item->bar)->toBeSame($dependency);
  }

  /**
   * Asserts that an exception is thrown when attempting to get a class that does not exist.
   */
  public function testThrowsWhenGettingNonExistentClass(): void {
    expect(() ==> {
      $container = new ReflectionContainer();
      $container->get('Whoooooopyyyy');
    })->toThrow(NotFoundException::class);
  }

  /**
   * Asserts that call reflects on a closure and injects arguments.
   */
  public function testCallReflectsOnClosureArguments(): void {
    $container = new ReflectionContainer();
    $foo = $container->call((Foo $foo): Foo ==> $foo);
    expect($foo)->toBeInstanceOf(Foo::class);
    $foo as Foo;
    expect($foo->bar)->toBeInstanceOf(Bar::class);
  }

  /**
   * Asserts that call reflects on an instance method and injects arguments.
   */
  public function testCallReflectsOnInstanceMethodArguments(): void {
    $container = new ReflectionContainer();
    $foo = new Foo(null);
    $container->call(inst_meth($foo, 'setBar'));
    expect($foo)->toBeInstanceOf(Foo::class);
    expect($foo->bar)->toBeInstanceOf(Bar::class);
  }

  /**
   * Asserts that call reflects on a static method and injects arguments.
   */
  public function testCallReflectsOnStaticMethodArguments(): void {
    $container = new ReflectionContainer();
    $container->setContainer($container);
    $container->call(class_meth(Asset\Foo::class, 'staticSetBar'));
    expect(Asset\Foo::$staticBar)->toBeInstanceOf(Bar::class);
    expect(Asset\Foo::$staticHello)->toBePHPEqual('hello world');
  }

  /**
   * Asserts that exception is thrown when an argument cannot be resolved.
   */
  public function testThrowsWhenArgumentCannotBeResolved(): void {
    expect(() ==> {
      $container = new ReflectionContainer();
      $container->call(inst_meth(new Bar(), 'setSomething'));
    })->toThrow(NotFoundException::class);
  }

  public function testInvokableClass(): void {
    $container = new ReflectionContainer();
    $call = (Bar $x) ==> $x;
    $bar = $container->call($call);
    expect($bar)->toBeInstanceOf(Bar::class);
    $call = inst_meth(new FooCallable(), 'call');
    $foo = $container->call($call, dict['bar' => $bar]);
    expect($foo)->toBeInstanceOf(Foo::class);
    $bar as Bar;
    $foo as Foo;
    expect($foo->bar)->toBeInstanceOf(Bar::class);
    expect($foo->bar)->toBeSame($bar);
  }
}
