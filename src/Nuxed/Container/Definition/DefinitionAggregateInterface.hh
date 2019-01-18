<?hh // strict

namespace Nuxed\Container\Definition;

use type IteratorAggregate;
use type Nuxed\Contract\Container\ContainerAwareInterface;

interface DefinitionAggregateInterface
  extends ContainerAwareInterface, IteratorAggregate<DefinitionInterface> {
  /**
   * Add a definition to the aggregate.
   */
  public function add(
    string $id,
    mixed $definition,
    bool $shared = false,
  ): DefinitionInterface;

  /**
   * Checks whether alias exists as definition.
   *
   * @param string $id
   *
   * @return boolean
   */
  public function has(string $id): bool;

  /**
   * Checks whether tag exists as definition.
   *
   * @param string $tag
   *
   * @return boolean
   */
  public function hasTag(string $tag): bool;

  /**
   * Get the definition to be extended.
   *
   * @param string $id
   *
   * @return \Nuxed\Container\Definition\DefinitionInterface
   */
  public function getDefinition(string $id): DefinitionInterface;

  /**
   * Resolve and build a concrete value from an id/alias.
   *
   * @param string  $id
   * @param boolean $new
   *
   * @return mixed
   */
  public function resolve(string $id, bool $new = false): mixed;

  /**
   * Resolve and build a vector of concrete values from a tag.
   *
   * @param string  $tag
   * @param boolean $new
   *
   * @return vec<mixed>
   */
  public function resolveTagged(string $tag, bool $new = false): vec<mixed>;
}
