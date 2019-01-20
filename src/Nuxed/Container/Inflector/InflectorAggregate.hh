<?hh // strict

namespace Nuxed\Container\Inflector;

use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Container\ContainerAwareTrait;
use type Iterator;
use function is_a;

class InflectorAggregate implements InflectorAggregateInterface {
  use ContainerAwareTrait;
  protected vec<InflectorInterface> $inflectors;

  public function __construct(
    Container<InflectorInterface> $inflectors = vec[],
  ) {
    $this->inflectors = vec($inflectors);
  }

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
  public function getIterator(): Iterator<InflectorInterface> {
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

      if ($inflector is ContainerAwareInterface) {
        $inflector->setContainer($this->getContainer());
      }

      // UNSAFE
      $inflector->inflect($object);
    }

    return $object;
  }
}
