namespace Nuxed\Test\Container;

use namespace Nuxed\Container;
use namespace Facebook\HackTest;
use namespace His\Container\Exception;
use function Facebook\FBExpect\expect;

class ServiceContainerTest extends HackTest\HackTest {
  public function testHas(): void {
    $container = new Container\ServiceContainer(dict[]);
    expect($container->has(Map::class))->toBeFalse();

    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($_) ==> Map {}),
    );
    $container = new Container\ServiceContainer(dict[
      Map::class => $definition,
    ]);
    expect($container->has(Map::class))->toBeTrue();

    $container = new Container\ServiceContainer(dict[], vec[$container]);
    expect($container->has(Map::class))->toBeTrue();
    expect($container->has(Set::class))->toBeFalse();
  }

  public function testGet(): void {
    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($_) ==> Map {}),
    );
    $container = new Container\ServiceContainer(dict[
      Map::class => $definition,
    ]);
    expect($container->get(Map::class))->toBeInstanceOf(Map::class);

    $container = new Container\ServiceContainer(dict[]);
    expect(() ==> $container->get(Map::class))
      ->toThrow(Exception\NotFoundExceptionInterface::class);

    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(
        ($_) ==> {
          throw new \Exception('foo');
        },
      ),
    );
    $container = new Container\ServiceContainer(dict[
      Map::class => $definition,
    ]);

    expect(() ==> $container->get(Map::class))
      ->toThrow(Exception\ContainerExceptionInterface::class, 'foo');

    $container = new Container\ServiceContainer(dict[], vec[$container]);

    expect(() ==> $container->get(Map::class))
      ->toThrow(Exception\ContainerExceptionInterface::class, 'delegate');

    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($_) ==> Map {}),
    );
    $container = new Container\ServiceContainer(dict[
      Map::class => $definition,
    ]);
    $container = new Container\ServiceContainer(dict[], vec[$container]);
    expect($container->get(Map::class))->toBeInstanceOf(Map::class);
  }
}
