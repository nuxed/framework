<?hh // strict

namespace Nuxed\Container\Inflector;

use type Nuxed\Container\ContainerAwareTrait;
use type Nuxed\Container\Argument\ArgumentResolverInterface;
use type Nuxed\Container\Argument\ArgumentResolverTrait;
use type ReflectionProperty;
use function get_class;
use function inst_meth;

class Inflector implements ArgumentResolverInterface, InflectorInterface {
  use ArgumentResolverTrait;
  use ContainerAwareTrait;

  protected string $type;

  protected ?(function(mixed): void) $callback;

  protected dict<string, vec<mixed>> $methods = dict[];

  protected dict<string, mixed> $properties = dict[];

  public function __construct(
    string $type,
    ?(function(mixed): void) $callback = null,
  ) {
    $this->type = $type;
    $this->callback = $callback;
  }

  /**
   * {@inheritdoc}
   */
  public function getType(): string {
    return $this->type;
  }

  /**
   * {@inheritdoc}
   */
  public function invokeMethod(
    string $name,
    vec<mixed> $args,
  ): InflectorInterface {
    $this->methods[$name] = $args;

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function invokeMethods(
    dict<string, vec<mixed>> $methods,
  ): InflectorInterface {
    foreach ($methods as $name => $args) {
      $this->invokeMethod($name, $args);
    }

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function setProperty(
    string $property,
    mixed $value,
  ): InflectorInterface {
    $this->properties[$property] = $this->resolveArguments(vec[$value])[0];

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function setProperties(
    dict<string, mixed> $properties,
  ): InflectorInterface {
    foreach ($properties as $property => $value) {
      $this->setProperty($property, $value);
    }

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function inflect(mixed $object): void {
    $properties = dict[];
    foreach ($this->properties as $key => $value) {
      $arguments = vec[$value];
      $resolved = $this->resolveArguments($arguments);
      $properties[$key] = $resolved[0];
    }

    foreach ($properties as $property => $value) {
      $reflection = new ReflectionProperty(get_class($object), $property);
      $reflection->setValue($object, $value);
    }

    foreach ($this->methods as $method => $args) {
      $args = $this->resolveArguments($args);
      /* HH_IGNORE_ERROR[2025] */
      $callback = inst_meth($object, $method);
      $callback(...$args);
    }

    if (null !== $this->callback) {
      $callback = $this->callback;
      $callback($object);
    }
  }
}
