namespace Nuxed\Container\ServiceProvider;

use namespace HH\Lib\C;
use type Nuxed\Container\ContainerAwareTrait;
use type Nuxed\Container\Container;
use type Nuxed\Container\Inflector\InflectorInterface;
use type Nuxed\Container\Definition\DefinitionInterface;
use function get_class;

abstract class AbstractServiceProvider implements ServiceProviderInterface {
  use ContainerAwareTrait;

  protected vec<string> $provides = vec[];

  protected string $identifier;

  public function __construct() {
    $this->identifier = get_class($this);
  }

  /**
   * {@inheritdoc}
   */
  public function provides(string $alias): bool {
    return C\contains($this->provides, $alias);
  }

  /**
   * {@inheritdoc}
   */
  public function setIdentifier(string $id): ServiceProviderInterface {
    $this->identifier = $id;

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function getIdentifier(): string {
    return $this->identifier;
  }

  private function getNuxedContainer(): Container {
    return $this->getContainer() as Container;
  }

  /**
   * Allows for manipulation of specific types on resolution.
   */
  public function inflector(
    string $type,
    ?(function(mixed): void) $callback = null,
  ): InflectorInterface {
    return $this->getNuxedContainer()->inflector($type, $callback);
  }

  /**
   * Get a definition to extend.
   */
  public function extend(string $id): DefinitionInterface {
    return $this->getNuxedContainer()->extend($id);
  }

  /**
   * Add an item to the container.
   */
  public function add(
    string $id,
    mixed $concrete = null,
    ?bool $shared = null,
  ): DefinitionInterface {
    return $this->getNuxedContainer()->add($id, $concrete, $shared);
  }

  /**
   * Proxy to add with shared as true.
   */
  public function share(
    string $id,
    mixed $concrete = null,
  ): DefinitionInterface {
    return $this->add($id, $concrete, true);
  }
}
