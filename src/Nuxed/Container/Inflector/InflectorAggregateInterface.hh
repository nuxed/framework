<?hh // strict

namespace Nuxed\Container\Inflector;

use type IteratorAggregate;
use type Nuxed\Contract\Container\ContainerAwareInterface;

interface InflectorAggregateInterface
  extends ContainerAwareInterface, IteratorAggregate<Inflector> {
  /**
   * Add an inflector to the aggregate.
   */
  public function add(
    string $type,
    ?(function(mixed): void) $callback = null,
  ): Inflector;

  /**
   * Applies all inflectors to an object.
   *
   * @param  object $object
   * @return object
   */
  public function inflect(mixed $object): mixed;
}
