<?hh // strict

namespace Nuxed\Container;

use type Nuxed\Container\Exception\ContainerException;
use type Nuxed\Contract\Container\ContainerInterface;
use type Nuxed\Contract\Container\ContainerAwareInterface;

trait ContainerAwareTrait implements ContainerAwareInterface {
  protected ?ContainerInterface $container;

  /**
   * Set a container.
   */
  public function setContainer(ContainerInterface $container): this {
    $this->container = $container;
    return $this;
  }

  /**
   * Get the container.
   */
  public function getContainer(): ContainerInterface {
    if ($this->container instanceof ContainerInterface) {
      return $this->container;
    }

    throw new ContainerException('No container implementation has been set.');
  }

  protected function hasContainer(): bool {
    return $this->container is nonnull;
  }
}
