namespace Nuxed\Container\ServiceProvider;

use type Nuxed\Contract\Container\ContainerAwareInterface;

interface ServiceProviderInterface extends ContainerAwareInterface {
  /**
   * Returns a boolean if checking whether this provider provides a specific
   * service.
   *
   * @param string $service
   *
   * @return boolean
   */
  public function provides(string $service): bool;

  /**
   * Use the register method to register items with the container via the
   * protected $this->container property or the `getContainer` method
   * from the ContainerAwareTrait.
   *
   * @return void
   */
  public function register(): void;

  /**
   * Set a custom id for the service provider. This enables
   * registering the same service provider multiple times.
   *
   * @param string $id
   *
   * @return self
   */
  public function setIdentifier(string $id): ServiceProviderInterface;

  /**
   * The id of the service provider uniquely identifies it, so
   * that we can quickly determine if it has already been registered.
   * Defaults to get_class($provider).
   *
   * @return string
   */
  public function getIdentifier(): string;
}
