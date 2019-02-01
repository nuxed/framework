<?hh // strict

namespace Nuxed\Test\Container\Argument;

use namespace HH\Lib\C;
use type Facebook\HackTest\HackTest;
use type Nuxed\Container\Argument\RawArgument;
use type Nuxed\Container\Exception\NotFoundException;
use type Nuxed\Container\Container;
use type Nuxed\Test\Container\Asset\QuxArgumentResolver;
use type Nuxed\Test\Container\Asset\Foo;
use type ReflectionFunction;
use function Facebook\FBExpect\expect;

class ArgumentResolverTest extends HackTest {
  /**
   * Asserts that the resolver proxies to container for resolution.
   */
  public function testResolverResolvesFromContainer(): void {
    $resolver = new QuxArgumentResolver();

    $container = new Container();

    $container->add('alias1', () ==> $resolver);

    $resolver->setContainer($container);

    $args = $resolver->resolveArguments(vec[
      'alias1',
      'alias2',
    ]);

    expect(C\firstx($args))->toBeSame($resolver);
    expect(C\lastx($args))->toBeSame('alias2');
  }

  /**
   * Asserts that the resolver resolves raw arguments.
   */
  public function testResolverResolvesResolvesRawArguments(): void {
    $resolver = new QuxArgumentResolver();

    $container = new Container();

    $container->add('alias1', () ==> new RawArgument('value1'));

    $resolver->setContainer($container);

    $args = $resolver->resolveArguments(vec[
      'alias1',
      new RawArgument('value2'),
    ]);

    expect(C\firstx($args))->toBeSame('value1');
    expect(C\lastx($args))->toBeSame('value2');
  }

  /**
   * Asserts that the resolver can resolve arguments via reflection.
   */
  public function testResolverResolvesArgumentsViaReflection(): void {
    $llama = (Foo $foo, string $param2, string $param3 = 'default'): string ==>
      'i am a '.$param2;

    $method = new \ReflectionFunction($llama);
    $container = new Container();

    $resolver = new QuxArgumentResolver();

    $resolver->setContainer($container);

    $foo = new Foo(null);

    /*------------------------------------------------*/

    $args = vec(
      $resolver->reflectArguments($method, dict[
        'param2' => 'llama',
        'foo' => $foo,
      ]),
    );

    expect($args[0])->toBeSame($foo);
    expect($args[1])->toBeSame('llama');
    expect($args[2])->toBeSame('default');

    /*------------------------------------------------*/

    $args = vec(
      $resolver->reflectArguments($method, dict[
        'param2' => 'llama',
      ]),
    );

    expect($args[0])->toBeSame(Foo::class);
    expect($args[1])->toBeSame('llama');
    expect($args[2])->toBeSame('default');
  }

  /**
   * Asserts that the resolver throws an exception when reflection can't resolve a value.
   */
  public function testResolverThrowsExceptionWhenReflectionDoesNotResolve(
  ): void {
    expect(() ==> {

      $func = ($param1): string ==> (string)$param1;

      $method = new ReflectionFunction($func);

      $resolver = new QuxArgumentResolver();

      $args = $resolver->reflectArguments($method);

    })->toThrow(NotFoundException::class);
  }
}
