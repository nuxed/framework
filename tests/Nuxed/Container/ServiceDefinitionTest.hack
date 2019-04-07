namespace Nuxed\Test\Container;

use namespace Nuxed\Container;
use namespace Facebook\HackTest;
use function Facebook\FBExpect\expect;

class ServiceDefinitionTest extends HackTest\HackTest {
  public function testResolve(): void {
    $container = new Container\ServiceContainer(dict[]);
    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($container) ==> Map {'container' => $container}),
    );

    $map = $definition->resolve($container);
    expect($map->at('container'))->toBeSame($container);
  }

  public function testResolveShared(): void {
    $container = new Container\ServiceContainer(dict[]);
    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($container) ==> Map {'container' => $container}),
      true,
    );

    $map1 = $definition->resolve($container);
    $map2 = $definition->resolve($container);
    expect($map1)->toBeSame($map2);
  }

  public function testResolveNonShared(): void {
    $container = new Container\ServiceContainer(dict[]);
    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($container) ==> Map {'container' => $container}),
      false,
    );

    $map1 = $definition->resolve($container);
    $map2 = $definition->resolve($container);
    expect($map1)->toNotBeSame($map2);
  }

  public function testSettersAndGetters(): void {
    $factory =
      Container\factory(($container) ==> Map {'container' => $container});
    $definition = new Container\ServiceDefinition(Map::class, $factory, false);

    expect($definition->getId())->toBeSame(Map::class);
    expect($definition->getFactory())->toBeSame($factory);
    expect($definition->getInflectors())->toBeEmpty();
    expect($definition->isShared())->toBeFalse();

    $factory2 = Container\factory(($_) ==> Map {'foo' => 'bar'});
    $definition->setFactory($factory2);

    expect($definition->getFactory())->toNotBeSame($factory);
    expect($definition->getFactory())->toBeSame($factory2);

    $definition->setShared(true);
    expect($definition->isShared())->toBeTrue();
    $definition->setShared(false);
    expect($definition->isShared())->toBeFalse();

    $inflector = Container\inflector(($map, $container) ==> $map);
    $definition->inflect($inflector);

    expect($definition->getInflectors())->toContain($inflector);
  }

  public function testSharedDefinitionIsResetAfterChangingFactory(): void {
    $container = new Container\ServiceContainer(dict[]);
    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($_) ==> Map {'foo' => 'bar'}),
      true,
    );

    $map1 = $definition->resolve($container);
    $map2 = $definition->resolve($container);

    expect($map1->at('foo'))->toBeSame('bar');
    expect($map1)->toBeSame($map2);

    $definition->setFactory(Container\factory(($_) ==> Map {'baz' => 'qux'}));

    $map3 = $definition->resolve($container);

    expect($map3)->toNotBeSame($map1);
    expect($map3)->toNotBeSame($map2);
    expect($map3->at('baz'))->toBeSame('qux');
  }

  public function testSharedDefinitionIsResetAfterAddingInflector(): void {
    $container = new Container\ServiceContainer(dict[]);
    $definition = new Container\ServiceDefinition(
      Map::class,
      Container\factory(($_) ==> Map {'foo' => 'bar'}),
      true,
    );

    $map1 = $definition->resolve($container);
    $map2 = $definition->resolve($container);

    expect($map1->at('foo'))->toBeSame('bar');
    expect($map1)->toBeSame($map2);

    $definition->inflect(Container\inflector(
      ($map, $_) ==> Map {'baz' => 'qux'}
        |> $$->addAll($map->items()),
    ));

    $map3 = $definition->resolve($container);

    expect($map3)->toNotBeSame($map1);
    expect($map3)->toNotBeSame($map2);
    expect($map3->at('baz'))->toBeSame('qux');
    expect($map3->at('foo'))->toBeSame('bar');
  }
}
