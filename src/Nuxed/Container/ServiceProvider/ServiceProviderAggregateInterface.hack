namespace Nuxed\Container\ServiceProvider;

use type IteratorAggregate;
use type Nuxed\Contract\Container\ContainerAwareInterface;

interface ServiceProviderAggregateInterface
  extends ContainerAwareInterface, IteratorAggregate<ServiceProviderInterface> {
  /**
   * Add a service provider to the aggregate.
   *
   * @param string|\Nuxed\Container\ServiceProvider\ServiceProviderInterface $provider
   */
  public function add(mixed $provider): this;

  /**
   * Determines whether a service is provided by the aggregate.
   *
   * in case a ServiceProvider provides the given service, this method
   * MUST return true and the service identifier, otherwise, return false and null.
   */
  public function provides(string $service): (bool, ?string);

  /**
   * Invokes the register method of a provider that provides a specific service.
   */
  public function register(string $service): void;
}
