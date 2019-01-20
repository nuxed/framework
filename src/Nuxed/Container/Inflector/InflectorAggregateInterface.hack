namespace Nuxed\Container\Inflector;

use type IteratorAggregate;
use type Nuxed\Contract\Container\ContainerAwareInterface;

interface InflectorAggregateInterface
  extends ContainerAwareInterface, IteratorAggregate<InflectorInterface> {
  /**
   * Add an inflector to the aggregate.
   */
  public function add(
    string $type,
    ?(function(mixed): void) $callback = null,
  ): InflectorInterface;

  /**
   * Applies all inflectors to an object.
   *
   * @param  object $object
   * @return object
   */
  public function inflect(mixed $object): mixed;
}
