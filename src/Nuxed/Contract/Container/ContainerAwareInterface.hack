namespace Nuxed\Contract\Container;

use type Nuxed\Contract\Container\ContainerInterface;

interface ContainerAwareInterface {
  /**
   * Set a container
   */
  public function setContainer(ContainerInterface $container): this;

  /**
   * Get the container
   */
  public function getContainer(): ContainerInterface;
}
