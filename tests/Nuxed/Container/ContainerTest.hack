namespace Nuxed\Test\Container;

use namespace HH\Lib\C;
use type Nuxed\Container\Definition\DefinitionInterface;
use type Nuxed\Container\Exception\NotFoundException;
use type Nuxed\Test\Container\Asset\Foo;
use type Nuxed\Test\Container\Asset\Bar;
use type Nuxed\Test\Container\Asset\FooServiceProvider;
use type Nuxed\Container\Container;
use type Nuxed\Container\ReflectionContainer;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class ContainerTest extends HackTest {
  /**
   * Asserts that the container can add and get a service.
   */
  public function testContainerAddsAndGets(): void {
    $container = new Container();

    $container->add(Foo::class);

    expect($container->has(Foo::class))->toBeTrue();

    $foo = $container->get(Foo::class);

    expect($foo)->toBeInstanceOf(Foo::class);
  }

  /**
   * Asserts that the container can add and get a service defined as shared.
   */
  public function testContainerAddsAndGetsShared(): void {
    $container = new Container();

    $container->share(Foo::class);

    expect($container->has(Foo::class))->toBeTrue();

    $fooOne = $container->get(Foo::class);
    $fooTwo = $container->get(Foo::class);

    expect($fooOne)->toBeInstanceOf(Foo::class);
    expect($fooTwo)->toBeInstanceOf(Foo::class);
    expect($fooTwo)->toBeSame($fooOne);
  }

  /**
   * Asserts that the container can add and get a service defined as shared.
   */
  public function testContainerAddsAndGetsSharedByDefault(): void {
    $container = (new Container())->defaultToShared();

    $container->add(Foo::class);

    expect($container->has(Foo::class))->toBeTrue();

    $fooOne = $container->get(Foo::class);
    $fooTwo = $container->get(Foo::class);

    expect($fooOne)->toBeInstanceOf(Foo::class);
    expect($fooTwo)->toBeInstanceOf(Foo::class);
    expect($fooTwo)->toBeSame($fooOne);
  }

  /**
   * Asserts that the container can add and get a service defined as non-shared with defaultToShared enabled.
   */
  public function testContainerAddsNonSharedWithSharedByDefault(): void {
    $container = (new Container())->defaultToShared();

    $container->add(Foo::class, null, false);

    expect($container->has(Foo::class))->toBeTrue();

    $fooOne = $container->get(Foo::class);
    $fooTwo = $container->get(Foo::class);

    expect($fooOne)->toBeInstanceOf(Foo::class);
    expect($fooTwo)->toBeInstanceOf(Foo::class);
    expect($fooTwo)->toNotBeSame($fooOne);
  }

  /**
   * Asserts that the container can add and get services by tag.
   */
  public function testContainerAddsAndGetsFromTag(): void {
    $container = new Container();

    $container->add(Foo::class)->addTag('foobar');
    $container->add(Bar::class)->addTag('foobar');

    expect($container->has(Foo::class))->toBeTrue();

    expect($container->has('foobar'))->toBeTrue();

    $vec = $container->get('foobar');

    /* HH_IGNORE_ERROR[4110] */
    expect(C\count($vec))->toBePHPEqual(2);
    /* HH_IGNORE_ERROR[4110] */
    expect(C\firstx($vec))->toBeInstanceOf(Foo::class);
    /* HH_IGNORE_ERROR[4110] */
    expect(C\lastx($vec))->toBeInstanceOf(Bar::class);
  }

  /**
   * Asserts that the container can add and get a service from service provider.
   */
  public function testContainerAddsAndGetsWithServiceProvider(): void {
    $provider = new FooServiceProvider();

    $container = new Container();

    $container->addServiceProvider($provider);

    //expect($container->has(Foo::class))->toBeTrue();

    $foo = $container->get(Foo::class);

    expect($foo)->toBeInstanceOf(Foo::class);
  }

  /**
   * Asserts that the container can add and get a service from a delegate.
   */
  public function testContainerAddsAndGetsFromDelegate(): void {
    $delegate = new ReflectionContainer();
    $container = new Container();

    $container->delegate($delegate);

    $foo = $container->get(Foo::class);

    expect($foo)->toBeInstanceOf(Foo::class);
  }

  /**
   * Asserts that the container throws an exception when cannot find service.
   */
  public function testContainerThrowsWhenCannotGetService(): void {
    expect(() ==> {
      $container = new Container();
      expect($container->has(Foo::class))->toBeFalse();
      $container->get(Foo::class);
    })->toThrow(NotFoundException::class);
  }

  /**
   * Asserts that the container can find a definition to extend.
   */
  public function testContainerCanExtendDefinition(): void {
    $container = new Container();

    $container->add(Foo::class);

    $definition = $container->extend(Foo::class);

    expect($definition)->toBeInstanceOf(DefinitionInterface::class);
  }

  /**
   * Asserts that the container can find a definition to extend from service provider.
   */
  public function testContainerCanExtendDefinitionFromServiceProvider(): void {
    $provider = new FooServiceProvider();

    $container = new Container();

    $container->addServiceProvider($provider);

    $definition = $container->extend(Foo::class);

    expect($definition)->toBeInstanceOf(DefinitionInterface::class);
  }

  /**
   * Asserts that the container throws an exception when can't find definition to extend.
   */
  public function testContainerThrowsWhenCannotGetDefinitionToExtend(): void {
    expect(() ==> {
      $container = new Container();
      expect($container->has(Foo::class))->toBeFalse();
      $container->extend(Foo::class);
    })->toThrow(NotFoundException::class);
  }

  /**
   * Asserts that the container adds and invokes an inflector.
   */
  public function testContainerAddsAndInvokesInflector(): void {
    $container = new Container();

    $container->inflector(Foo::class)->setProperty('bar', Bar::class);

    $container->add(Foo::class);
    $container->add(Bar::class);

    $foo = $container->get(Foo::class);

    expect($foo)->toBeInstanceOf(Foo::class);
    /* HH_IGNORE_ERROR[4064] */
    expect($foo->bar)->toBeInstanceOf(Bar::class);
  }
}
