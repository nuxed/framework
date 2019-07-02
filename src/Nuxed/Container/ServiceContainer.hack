namespace Nuxed\Container;

use namespace His;
use namespace HH\Lib\{C, Str};

type IServiceContainer = His\Container\ContainerInterface;

<<__Sealed(ReflectionServiceContainer::class), __ConsistentConstruct>>
class ServiceContainer implements His\Container\ContainerInterface {
  protected vec<IServiceContainer> $delegates;

  public function __construct(
    protected KeyedContainer<string, ServiceDefinition<mixed>> $definitions =
      dict[],
    Container<IServiceContainer> $delegates = vec[],
  ) {
    $this->delegates = vec($delegates);
  }

  public function get<T>(typename<T> $service): T {
    if (C\contains_key($this->definitions, $service)) {
      $def = $this->definitions[$service] as ServiceDefinition<_>;

      try {
        /* HH_FIXME[4110] - we can't type hint the follwoing expression. */
        return $def->resolve($this);
      } catch (\Exception $e) {
        throw new Exception\ContainerException(
          Str\format(
            'Exception thrown while trying to create service (%s) : %s',
            $service,
            Str\ends_with($e->getMessage(), '.')
              ? $e->getMessage()
              : $e->getMessage().'.',
          ),
          $e->getCode(),
          $e,
        );
      }
    }

    foreach ($this->delegates as $container) {
      if ($container->has($service)) {
        try {
          return $container->get($service);
        } catch (\Exception $e) {
          throw new Exception\ContainerException(
            Str\format(
              'Exception thrown while resolving service (%s) from a delegate container : %s',
              $service,
              Str\ends_with($e->getMessage(), '.')
                ? $e->getMessage()
                : $e->getMessage().'.',
            ),
            $e->getCode(),
            $e,
          );
        }
      }
    }

    throw new Exception\NotFoundException(Str\format(
      'Service (%s) is not managed by the service container or delegates.',
      $service,
    ));
  }

  public function has<T>(typename<T> $service): bool {
    if (C\contains_key($this->definitions, $service)) {
      return true;
    }

    foreach ($this->delegates as $delegate) {
      if ($delegate->has($service)) {
        return true;
      }
    }

    return false;
  }

  public function delegate(IServiceContainer $delegate): this {
    $this->delegates[] = $delegate;

    return $this;
  }
}
