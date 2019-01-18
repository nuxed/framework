<?hh // strict

namespace Nuxed\Container\ServiceProvider;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Container\ContainerAwareTrait;
use type Nuxed\Container\Exception\ContainerException;
use type ReflectionClass;
use function class_exists;

class ServiceProviderAggregate implements ServiceProviderAggregateInterface {
  use ContainerAwareTrait;

  protected vec<ServiceProviderInterface> $providers = vec[];

  protected vec<string> $registered = vec[];

  public function __construct() {
    $this->providers = vec[];
    $this->registered = vec[];
  }

  /**
   * {@inheritdoc}
   */
  public function add(mixed $provider): this {
    if (($provider is string) && $this->getContainer()->has($provider)) {
      $provider = $this->getContainer()->get($provider);
    } elseif (($provider is string) && class_exists($provider)) {
      $reflection = new ReflectionClass($provider);
      $provider = $reflection->newInstance();
    }

    if ($provider instanceof ContainerAwareInterface) {
      $provider->setContainer($this->getContainer());
    }

    if ($provider instanceof BootableServiceProviderInterface) {
      $provider->boot();
    }

    if ($provider instanceof ServiceProviderInterface) {
      $this->providers[] = $provider;

      return $this;
    }

    throw new ContainerException(
      'A service provider must be a fully qualified class name or instance '.
      'of (\Nuxed\Container\ServiceProvider\ServiceProviderInterface)',
    );
  }

  /**
   * {@inheritdoc}
   */
  public function provides(string $service): bool {
    foreach ($this->providers as $provider) {
      if ($provider->provides($service)) {
        return true;
      }
    }

    return false;
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
  public function register(string $service): void {
    if (!$this->provides($service)) {
      throw new ContainerException(
        Str\format('(%s) is not provided by a service provider', $service),
      );
    }

    foreach ($this->getIterator() as $provider) {
      if (C\contains($this->registered, $provider->getIdentifier())) {
        continue;
      }

      if ($provider->provides($service)) {
        $provider->register();
        $this->registered[] = $provider->getIdentifier();
      }
    }
  }
}
