<?hh // strict

namespace Nuxed\Container\Inflector;

use type Nuxed\Container\ContainerAwareTrait;
use type Iterator;
use function is_a;

class InflectorAggregate implements InflectorAggregateInterface {
  use ContainerAwareTrait;

  public function __construct(protected vec<Inflector> $inflectors = vec[]) {}

  /**
   * {@inheritdoc}
   */
  public function add(
    string $type,
    ?(function(mixed): void) $callback = null,
  ): Inflector {
    $inflector = new Inflector($type, $callback);

    $this->inflectors[] = $inflector;

    return $inflector;
  }

  /**
   * {@inheritdoc}
   */
  public function getIterator(): Iterator<Inflector> {
    return (new Vector($this->inflectors))->getIterator();
  }

  /**
   * {@inheritdoc}
   */
  public function inflect(mixed $object): mixed {
    foreach ($this->getIterator() as $inflector) {
      $type = $inflector->getType();

      if (!is_a($object, $type)) {
        continue;
      }

      $inflector->setContainer($this->getContainer());
      $inflector->inflect($object);
    }

    return $object;
  }
}
