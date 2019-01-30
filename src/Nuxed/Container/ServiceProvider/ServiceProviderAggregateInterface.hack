namespace Nuxed\Container\ServiceProvider;

use type Nuxed\Container\Container;
use type IteratorAggregate;

interface ServiceProviderAggregateInterface
  extends IteratorAggregate<ServiceProviderInterface> {
  /**
   * Add a service provider to the aggregate.
   */
  public function add(ServiceProviderInterface $provider): this;

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
  public function register(string $service, Container $container): void;
}
