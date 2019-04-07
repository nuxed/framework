namespace Nuxed\Container;

use namespace Nuxed\Contract\Service;
use type His\Container\ContainerInterface;

final class ServiceDefinition<T> {
  private vec<Service\InflectorInterface<T>> $inflectors = vec[];
  private ?T $resolved = null;

  public function __construct(
    private typename<T> $id,
    private Service\FactoryInterface<T> $factory,
    private bool $shared = true,
  ) {}

  public function resolve(ContainerInterface $container): T {
    if ($this->isShared() && $this->resolved is nonnull) {
      return $this->resolved;
    }

    $object = $this->factory->create($container);
    foreach ($this->inflectors as $inflector) {
      $object = $inflector->inflect($object, $container);
    }

    return $this->resolved = $object;
  }

  public function getId(): typename<T> {
    return $this->id;
  }

  public function getFactory(): Service\FactoryInterface<T> {
    return $this->factory;
  }

  public function setFactory(Service\FactoryInterface<T> $factory): this {
    $this->factory = $factory;
    $this->resolved = null;

    return $this;
  }

  public function isShared(): bool {
    return $this->shared;
  }

  public function setShared(bool $shared = true): this {
    $this->shared = $shared;

    return $this;
  }

  public function getInflectors(): Container<Service\InflectorInterface<T>> {
    return $this->inflectors;
  }

  public function inflect(Service\InflectorInterface<T> $inflector): this {
    $this->inflectors[] = $inflector;

    return $this;
  }
}
