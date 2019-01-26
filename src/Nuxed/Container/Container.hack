namespace Nuxed\Container;

use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use type Nuxed\Container\Definition\DefinitionAggregate;
use type Nuxed\Container\Definition\DefinitionInterface;
use type Nuxed\Container\Definition\DefinitionAggregateInterface;
use type Nuxed\Container\Exception\ContainerException;
use type Nuxed\Container\Exception\NotFoundException;
use type Nuxed\Container\Inflector\InflectorAggregate;
use type Nuxed\Container\Inflector\InflectorInterface;
use type Nuxed\Container\Inflector\InflectorAggregateInterface;
use type Nuxed\Container\ServiceProvider\ServiceProviderAggregate;
use type Nuxed\Container\ServiceProvider\ServiceProviderAggregateInterface;
use type Nuxed\Contract\Container\ContainerInterface;
use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Contract\Service\ResetInterface;

class Container implements ContainerInterface {
  protected bool $defaultToShared = false;

  public function __construct(
    protected DefinitionAggregateInterface $definitions =
      new DefinitionAggregate(),
    protected ServiceProviderAggregateInterface $providers =
      new ServiceProviderAggregate(),
    protected InflectorAggregateInterface $inflectors =
      new InflectorAggregate(),
    protected vec<ContainerInterface> $delegates = vec[],
  ) {
    if ($this->definitions instanceof ContainerAwareInterface) {
      $this->definitions->setContainer($this);
    }

    if ($this->providers instanceof ContainerAwareInterface) {
      $this->providers->setContainer($this);
    }

    if ($this->inflectors instanceof ContainerAwareInterface) {
      $this->inflectors->setContainer($this);
    }

    $this->share(ContainerInterface::class, new Argument\RawArgument($this));
  }

  /**
   * Add an item to the container.
   */
  public function add(
    string $id,
    mixed $concrete = null,
    ?bool $shared = null,
  ): DefinitionInterface {
    $concrete = $concrete ?? $id;
    $shared = $shared ?? $this->defaultToShared;
    return $this->definitions->add($id, $concrete, $shared);
  }

  /**
   * Proxy to add with shared as true.
   */
  public function share(
    string $id,
    mixed $concrete = null,
  ): DefinitionInterface {
    return $this->add($id, $concrete, true);
  }

  /**
   * Whether the container should default to defining shared definitions.
   */
  public function defaultToShared(bool $shared = true): this {
    $this->defaultToShared = $shared;

    return $this;
  }

  /**
   * Get a definition to extend.
   */
  public function extend(string $id): DefinitionInterface {
    if ($this->providers->provides($id)[0]) {
      $this->providers->register($id);
    }

    if ($this->definitions->has($id)) {
      return $this->definitions->getDefinition($id);
    }

    throw new NotFoundException(
      Str\format(
        'Unable to extend alias (%s) as it is not being managed as a definition',
        $id,
      ),
    );
  }

  /**
   * Add a service provider.
   *
   * @param ServiceProviderInterface|string $provider
   */
  public function addServiceProvider(mixed $provider): this {
    $this->providers->add($provider);

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function get(string $id, bool $new = false): mixed {
    if ($this->definitions->has($id)) {

      $resolved = $this->definitions->resolve($id, $new);

      return $this->inflectors->inflect($resolved);
    }

    if ($this->definitions->hasTag($id)) {
      $tagged = $this->definitions->resolveTagged($id);

      return
        Vec\map($tagged, ($resolved) ==> $this->inflectors->inflect($resolved));
    }

    list($provided, $provider) = $this->providers->provides($id);
    if ($provided) {
      $this->providers->register($id);
      if (!$this->definitions->has($id) && !$this->definitions->hasTag($id)) {
        throw new ContainerException(Str\format(
          'Service Provider (%s) lied about providing (%s) service.',
          (string)$provider,
          $id,
        ));
      }
      return $this->get($id, $new);
    }

    foreach ($this->delegates as $delegate) {
      if ($delegate->has($id)) {
        $resolved = $delegate->get($id);
        return $this->inflectors->inflect($resolved);
      }
    }

    throw new NotFoundException(
      Str\format(
        'Alias (%s) is not being managed by the container or delegates',
        $id,
      ),
    );
  }

  /**
   * {@inheritdoc}
   */
  public function has(string $id): bool {
    if ($this->definitions->has($id)) {
      return true;
    }

    if ($this->definitions->hasTag($id)) {
      return true;
    }

    if ($this->providers->provides($id)[0]) {
      return true;
    }

    foreach ($this->delegates as $delegate) {
      if ($delegate->has($id)) {
        return true;
      }
    }

    return false;
  }

  /**
   * Allows for manipulation of specific types on resolution.
   */
  public function inflector(
    string $type,
    ?(function(mixed): void) $callback = null,
  ): InflectorInterface {
    return $this->inflectors->add($type, $callback);
  }

  /**
   * Delegate a backup container to be checked for services if it
   * cannot be resolved via this container.
   */
  public function delegate(ContainerInterface $container): this {
    $this->delegates[] = $container;

    if ($container instanceof ContainerAwareInterface) {
      $container->setContainer($this);
    }

    return $this;
  }

  public function reset(): void {
    $this->defaultToShared(false);

    foreach ($this->delegates as $delegate) {
      $delegate->reset();
    }

    if ($this->definitions is ResetInterface) {
      $this->definitions->reset();
    }

    if ($this->providers is ResetInterface) {
      $this->providers->reset();
    }

    if ($this->inflectors is ResetInterface) {
      $this->inflectors->reset();
    }
  }
}
