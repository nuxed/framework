namespace Nuxed\Container\ServiceProvider;

use type Nuxed\Container\Container;

interface ServiceProviderInterface {
  /**
   * Returns a boolean if checking whether this provider provides a specific
   * service.
   */
  public function provides(string $service): bool;

  /**
   * Use the register method to register items with the container via the
   * container instance.
   */
  public function register(Container $container): void;

  /**
   * Set a custom id for the service provider. This enables
   * registering the same service provider multiple times.
   */
  public function setIdentifier(string $id): ServiceProviderInterface;

  /**
   * The id of the service provider uniquely identifies it, so
   * that we can quickly determine if it has already been registered.
   * Defaults to get_class($provider).
   */
  public function getIdentifier(): string;
}
