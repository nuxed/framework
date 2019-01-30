<?hh // strict

namespace Nuxed\Container\ServiceProvider;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use type Nuxed\Container\Exception\ContainerException;
use type Nuxed\Container\Container;

class ServiceProviderAggregate implements ServiceProviderAggregateInterface {

  protected vec<ServiceProviderInterface> $providers = vec[];

  protected vec<string> $registered = vec[];

  /**
   * {@inheritdoc}
   */
  public function add(ServiceProviderInterface $provider): this {
    if ($provider instanceof BootableServiceProviderInterface) {
      $provider->boot();
    }

    $this->providers[] = $provider;

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function provides(string $service): (bool, ?string) {
    foreach ($this->providers as $provider) {
      if ($provider->provides($service)) {
        return tuple(true, $provider->getIdentifier());
      }
    }

    return tuple(false, null);
  }

  /**
   * {@inheritdoc}
   */
  public function getIterator(): Iterator<ServiceProviderInterface> {
    return (new Vector($this->providers))->getIterator();
  }

  /**
   * {@inheritdoc}
   */
  public function register(string $service, Container $container): void {
    if (!$this->provides($service)[0]) {
      throw new ContainerException(
        Str\format('(%s) is not provided by a service provider', $service),
      );
    }

    foreach ($this->providers as $provider) {
      if (C\contains($this->registered, $provider->getIdentifier())) {
        continue;
      }

      if ($provider->provides($service)) {
        $provider->register($container);
        $this->registered[] = $provider->getIdentifier();
      }
    }
  }
}
