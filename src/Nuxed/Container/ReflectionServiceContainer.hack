namespace Nuxed\Container;

use namespace His;
use namespace HH\Lib\Str;

final class ReflectionServiceContainer
  implements His\Container\ContainerInterface {
  private ?string $resolving = null;
  private ?string $current = null;

  public function __construct(
    private His\Container\ContainerInterface $inner = new ServiceContainer(),
  ) {}

  public function get<T>(typename<T> $service): T {
    if ($this->inner->has($service)) {
      return $this->inner->get($service);
    }

    if ($this->resolving === $service) {
      throw new Exception\ContainerException(Str\format(
        'Circle reference while trying to create service (%s) : %s requested %s while its being resolved.',
        $service,
        $this->current as string,
        $this->resolving as string,
      ));
    }

    if ($this->resolving is null) {
      $this->resolving = $service;
    }

    $reflection = new \ReflectionClass($service);
    if (!$reflection->isInstantiable()) {
      throw new Exception\ContainerException(Str\format(
        'Unable to resolve non-instantiable service (%s).',
        $service,
      ));
    }

    $constructor = $reflection->getConstructor();
    if (
      $constructor is null || $reflection->isSubclassOf(Service\Newable::class)
    ) {
      if ($service === $this->resolving) {
        $this->resolving = null;
      }
      return $reflection->newInstance();
    }

    $arguments = vec[];
    foreach ($constructor->getParameters() as $parameter) {
      $type = $parameter->getType() as nonnull;
      $request = (string)$type;
      if ($type->isBuiltin()) {
        throw new Exception\ContainerException(Str\format(
          'Unable to resolve builtin type (%s) parameter (%s) for service (%s).',
          $request,
          $parameter->getName(),
          $service,
        ));
      }

      if ($service !== $this->resolving) {
        $this->current = $service;
        $this->resolving = $request;
      }
      $arguments[] = $this->get(
        /* HH_FIXME[1001] */
        /* HH_FIXME[4110] */
        $request,
      );
    }

    if ($service === $this->resolving) {
      $this->resolving = null;
      $this->current = null;
    }
    return $reflection->newInstance(...$arguments);
  }

  public function has<T>(typename<T> $service): bool {
    return $this->inner->has($service) || \class_exists($service);
  }
}
