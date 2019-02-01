<?hh // strict

namespace Nuxed\Test\Container\Inflector;

use type Facebook\HackTest\HackTest;
use type Nuxed\Test\Container\Asset\BarContainerAware;
use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Container\Inflector\InflectorAggregate;
use type Nuxed\Container\Inflector\Inflector;
use type Nuxed\Container\Container;
use function Facebook\FBExpect\expect;

class InflectorAggregateTest extends HackTest {
  /**
   * Asserts that the aggregate can add an inflector.
   */
  public function testAggregateAddsInflector(): void {
    $aggregate = new InflectorAggregate();
    $inflector = $aggregate->add('Some\Type');

    expect($inflector)->toBeInstanceOf(Inflector::class);
    expect($inflector->getType())->toBeSame('Some\Type');
  }

  /**
   * Asserts that the aggregate iterates and inflects on an object.
   */
  public function testAggregateIteratesAndInflectsOnObject(): void {
    $aggregate = new InflectorAggregate();
    $container = new Container();
    $aggregate->setContainer($container);

    $aggregate->add(ContainerAwareInterface::class)
      ->invokeMethod('setContainer', vec[$container]);

    $aggregate->add('Ignored\Type');

    $containerAware = new BarContainerAware();
    $aggregate->inflect($containerAware);
    expect($containerAware->getContainer())->toBeSame($container);
  }
}
