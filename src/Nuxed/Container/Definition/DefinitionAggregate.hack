namespace Nuxed\Container\Definition;

use namespace HH\Lib\Str;
use type Iterator;
use type Nuxed\Container\ContainerAwareTrait;
use type Nuxed\Contract\Service\ResetInterface;
use type Nuxed\Container\Exception\NotFoundException;

class DefinitionAggregate
  implements DefinitionAggregateInterface, ResetInterface {
  use ContainerAwareTrait;

  protected vec<DefinitionInterface> $definitions;

  public function __construct(
    Container<DefinitionInterface> $definitions = vec[],
  ) {
    $this->definitions = vec($definitions);
  }

  /**
    * {@inheritdoc}
    */
  public function add(
    string $id,
    mixed $definition,
    bool $shared = false,
  ): DefinitionInterface {
    if (!$definition instanceof DefinitionInterface) {
      $definition = (new Definition($id, $definition));
    }
    $this->definitions[] = $definition
      ->setAlias($id)
      ->setShared($shared);
    return $definition;
  }

  /**
   * {@inheritdoc}
   */
  public function has(string $id): bool {
    foreach ($this->definitions as $definition) {
      if ($id === $definition->getAlias()) {
        return true;
      }
    }

    return false;
  }

  /**
   * {@inheritdoc}
   */
  public function hasTag(string $tag): bool {
    foreach ($this->definitions as $definition) {
      if ($definition->hasTag($tag)) {
        return true;
      }
    }

    return false;
  }

  /**
   * {@inheritdoc}
   */
  public function getDefinition(string $id): DefinitionInterface {
    foreach ($this->definitions as $definition) {
      if ($id === $definition->getAlias()) {
        $definition->setContainer($this->getContainer());
        return $definition;
      }
    }

    throw new NotFoundException(
      Str\format('Alias (%s) is not being handled as a definition.', $id),
    );
  }

  /**
   * {@inheritdoc}
   */
  public function resolve(string $id, bool $new = false): mixed {
    return $this->getDefinition($id)->resolve($new);
  }

  /**
   * {@inheritdoc}
   */
  public function resolveTagged(string $tag, bool $new = false): vec<mixed> {
    $vec = vec[];

    foreach ($this->getIterator() as $definition) {
      if ($definition->hasTag($tag)) {
        $vec[] = $definition->setContainer($this->getContainer())
          ->resolve($new);
      }
    }

    return $vec;
  }

  public function getIterator(): Iterator<DefinitionInterface> {
    return (new Vector($this->definitions))->getIterator();
  }

  public function reset(): void {
    foreach ($this->definitions as $definition) {
      if ($definition is ResetInterface) {
        $definition->reset();
      }
    }
  }
}
