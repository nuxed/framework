namespace Nuxed\Container;

use namespace HH\Lib\{C, Dict, Str};

final class ContainerBuilder {
  private dict<string, mixed> $definitions = dict[];

  public function register(IServiceProvider $provider): this {
    $provider->register($this);

    return $this;
  }

  public function add<T>(
    typename<T> $service,
    IFactory<T> $factory,
    bool $shared = true,
  ): this {
    $definition = new ServiceDefinition($service, $factory, $shared);
    $this->addDefinition($definition);
    return $this;
  }

  public function inflect<T>(
    typename<T> $service,
    IInflector<T> $inflector,
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
      /* HH_FIXME[4110] */
      return $this->definitions[$service];
    }

    throw new Exception\NotFoundException(Str\format(
      'Container builder doesn\'t contain definition for service (%s).',
      $service,
    ));
  }

  public function build(
    Container<IServiceContainer> $delegates = vec[],
    bool $reflection = true
  ): IServiceContainer {
    $definitions = Dict\map(
      $this->definitions,
      ($definition) ==> {
        $definition as ServiceDefinition<_>;
        return clone $definition;
      },
    );

    $class = $reflection
      ? ReflectionServiceContainer::class
      : ServiceContainer::class;

    return new $class(
      /* HH_IGNORE_ERROR[4110] */
      $definitions,
      $delegates,
    );
  }
}
