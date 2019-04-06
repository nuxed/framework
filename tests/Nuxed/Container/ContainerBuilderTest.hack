namespace Nuxed\Test\Container;

use namespace Nuxed\Container;
use namespace Facebook\HackTest;
use function Facebook\FBExpect\expect;

class ContainerBuilderTest extends HackTest\HackTest {
  public function testAdd(): void {
    $builder = new Container\ContainerBuilder();

    $builder->add(
      Vector::class,
      Container\factory(($_) ==> Vector {'foo', 'bar'}),
    );

    $container = $builder->build();

    expect($container->has(Map::class))->toBeFalse();
    expect($container->has(Set::class))->toBeFalse();
    expect($container->has(Vector::class))->toBeTrue();

    $firstVector = $container->get(Vector::class);
    expect($firstVector->containsKey(0))->toBeTrue();
    expect($firstVector->containsKey(1))->toBeTrue();
    expect($firstVector->at(0))->toBeSame('foo');
    expect($firstVector->at(1))->toBeSame('bar');
    expect($firstVector->count())->toBeSame(2);
    $secondVector = $container->get(Vector::class);
    expect($firstVector)->toBeSame($secondVector);
  }

  public function testAddShared(): void {
    $builder = new Container\ContainerBuilder();

    $builder->add(Set::class, Container\factory(($_) ==> Set {'foo'}), true);

    $container = $builder->build();

    expect($container->has(Map::class))->toBeFalse();
    expect($container->has(Set::class))->toBeTrue();
    expect($container->has(Vector::class))->toBeFalse();

    $firstSet = $container->get(Set::class);
    expect($firstSet->contains('foo'))->toBeTrue();
    expect($firstSet->firstValue())->toBeSame('foo');
    expect($firstSet->count())->toBeSame(1);
    $secondSet = $container->get(Set::class);
    expect($firstSet)->toBeSame($secondSet);
  }

  public function testAddNonShared(): void {
    $builder = new Container\ContainerBuilder();

    $builder->add(
      Map::class,
      Container\factory(($_) ==> Map {'foo' => 'bar'}),
      false,
    );

    $container = $builder->build();

    expect($container->has(Map::class))->toBeTrue();
    expect($container->has(Set::class))->toBeFalse();
    expect($container->has(Vector::class))->toBeFalse();

    $firstMap = $container->get(Map::class);
    expect($firstMap->contains('foo'))->toBeTrue();
    expect($firstMap->at('foo'))->toBeSame('bar');
    expect($firstMap->count())->toBeSame(1);
    $secondMap = $container->get(Map::class);
    expect($secondMap->contains('foo'))->toBeTrue();
    expect($secondMap->at('foo'))->toBeSame('bar');
    expect($secondMap->count())->toBeSame(1);
    expect($firstMap)->toNotBeSame($secondMap);
  }

  public function testInflect(): void {
    $builder = new Container\ContainerBuilder();

    $builder->add(
      Map::class,
      Container\factory(($_) ==> Map {'foo' => 'bar'}),
      false,
    );

    $builder->inflect(
      Map::class,
      Container\inflector(
        ($map, $_) ==>  Map { 'baz' => 'qux' }
          |> $$->addAll($map->items())
        ,
      ),
    );

    $container = $builder->build();

    $map = $container->get(Map::class);
    expect($map->count())->toBeSame(2);
    expect($map->contains('foo'))->toBeTrue();
    expect($map->contains('baz'))->toBeTrue();
    expect($map->at('foo'))->toBeSame('bar');
    expect($map->at('baz'))->toBeSame('qux');
  }

  public function testInflectThrowsIfServiceIsMissing(): void {
    $builder = new Container\ContainerBuilder();
    expect(() ==> $builder->inflect(
      Set::class,
      Container\inflector(($set, $_) ==> $set),
    ))->toThrow(Container\Exception\NotFoundException::class);
  }

  public function testBuild(): void {
    $builder1 = new Container\ContainerBuilder();
    $builder2 = new Container\ContainerBuilder();
    $builder3 = new Container\ContainerBuilder();
  
    $builder1->add(Vector::class, Container\factory(
      ($_) ==> Vector { 1, 2, 3, },
    ), true);
    
    $builder2->add(Set::class, Container\factory(
      ($_) ==> Set { 1, 2, 3, },
    ), true);
    
    $builder3->add(Map::class, Container\factory(
      ($_) ==> Map { 1 => 'foo', 2 => 'bar', 3 => 'baz', },
    ), true);
    
    $container1 = $builder1->build();
    $container2 = $builder2->build();
    $container3 = $builder3->build();

    expect($container1)->toNotBeSame($container2);
    expect($container2)->toNotBeSame($container3);
    expect($container3)->toNotBeSame($container1);

    expect($container1->has(Vector::class))->toBeTrue();
    expect($container1->has(Set::class))->toBeFalse();
    expect($container1->has(Map::class))->toBeFalse();
    
    expect($container2->has(Vector::class))->toBeFalse();
    expect($container2->has(Set::class))->toBeTrue();
    expect($container2->has(Map::class))->toBeFalse();
    
    expect($container3->has(Vector::class))->toBeFalse();
    expect($container3->has(Set::class))->toBeFalse();
    expect($container3->has(Map::class))->toBeTrue();

    $container1v2 = $builder1->build();
    expect($container1v2)->toNotBeSame($container1);

    expect($container1v2->has(Vector::class))->toBeTrue();
    expect($container1v2->has(Set::class))->toBeFalse();
    expect($container1v2->has(Map::class))->toBeFalse();
  }

  public function testBuildDelegates(): void {
    $builder1 = new Container\ContainerBuilder();
    $builder2 = new Container\ContainerBuilder();
    $builder3 = new Container\ContainerBuilder();
  
    $builder1->add(Vector::class, Container\factory(
      ($_) ==> Vector { 1, 2, 3, },
    ), true);
    
    $builder2->add(Set::class, Container\factory(
      ($_) ==> Set { 1, 2, 3, },
    ), true);
    
    $builder3->add(Map::class, Container\factory(
      ($_) ==> Map { 1 => 'foo', 2 => 'bar', 3 => 'baz', },
    ), true);
    
    $container1 = $builder1->build();
    $container2 = $builder2->build();
    $container3 = $builder3->build();

    $container2v2 = $builder2->build(vec[$container1, $container3]);
    expect($container2v2)->toNotBeSame($container2);

    expect($container2v2->has(Vector::class))->toBeTrue();
    expect($container2v2->has(Set::class))->toBeTrue();
    expect($container2v2->has(Map::class))->toBeTrue();
  }

  public function testInflectDoesntEffectBuiltContainers(): void {
    $builder = new Container\ContainerBuilder();

    $builder->add(Map::class, Container\factory(
      ($_) ==> Map { 'foo' => 'bar' }
    ), true);

    $container = $builder->build();

    $builder->inflect(Map::class, Container\inflector(
      ($map, $_) ==> Map { 'bar' => 'baz' }
        |> $$->addAll($map->items())
    ));

    $map = $container->get(Map::class);

    expect($map->count())->toBeSame(1);
    expect($map->contains('foo'))->toBeTrue();
    expect($map->contains('bar'))->toBeFalse();

    $container2 = $builder->build();

    $map2 = $container2->get(Map::class);

    expect($map2->count())->toBeSame(2);
    expect($map2->contains('foo'))->toBeTrue();
    expect($map2->contains('bar'))->toBeTrue();
  }
}
