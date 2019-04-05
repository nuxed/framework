namespace Nuxed\Container;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;
use namespace Nuxed\Contract\Service;
use type His\Container\ContainerInterface;

final class ContainerBuilder {

  private dict<string, mixed> $definitions = dict[];

  public function register(ServiceProviderInterface $provider): this {
    $provider->register($this);

    return $this;
  }

  public function add<T>(
    typename<T> $service,
    Service\FactoryInterface<T> $factory,
    bool $shared = true,
  ): this {
    $definition = new ServiceDefinition($service, $factory, $shared);
    $this->addDefinition($definition);
    return $this;
  }

  public function inflect<T>(
    typename<T> $service,
    Service\InflectorInterface<T> $inflector,
  ): this {
    $definition = $this->getDefinition($service);
    $definition->inflect($inflector);

    return $this;
  }

  private function addDefinition<T>(ServiceDefinition<T> $definition): void {
    $this->definitions[$definition->getId()] = $definition;
  }

  private function getDefinition<T>(
    typename<T> $service,
  ): ServiceDefinition<T> {
    if (C\contains_key($this->definitions, $service)) {
      // UNSAFE
      return $this->definitions[$service];
    }

    throw new Exception\NotFoundException(Str\format(
      'Container builder doesn\'t contain definition for service (%s).',
      $service,
    ));
  }

  public function build(
    Container<ContainerInterface> $delegates = vec[],
  ): ContainerInterface {
    return new ServiceContainer($this->definitions, $delegates);
  }
}