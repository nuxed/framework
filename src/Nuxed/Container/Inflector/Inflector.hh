<?hh // strict

namespace Nuxed\Container\Inflector;

use namespace HH\Lib\C;
use type Nuxed\Container\ContainerAwareTrait;
use type Nuxed\Container\Argument\ArgumentResolverInterface;
use type Nuxed\Container\Argument\ArgumentResolverTrait;
use type ReflectionObject;

class Inflector implements ArgumentResolverInterface, InflectorInterface {
  use ArgumentResolverTrait;
  use ContainerAwareTrait;

  protected string $type;

  protected ?(function(mixed): void) $callback;

  protected vec<(string, Container<mixed>)> $methods = vec[];

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
    Container<mixed> $args,
  ): InflectorInterface {
    $this->methods[] = tuple($name, $args);

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function invokeMethods(
    KeyedContainer<string, Container<mixed>> $methods,
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
    $this->properties[$property] =
      C\first($this->resolveArguments(vec[$value]));

    return $this;
  }

  /**
   * {@inheritdoc}
   */
  public function setProperties(
    KeyedContainer<string, mixed> $properties,
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
    $reflection = new ReflectionObject($object);

    foreach ($this->properties as $key => $value) {
      $resolved = $this->resolveArguments(vec[$value]);
      $properties[$key] = C\first($resolved);
    }

    foreach ($properties as $property => $value) {
      $reflectionProperty = $reflection->getProperty($property);
      $reflectionProperty->setValue($object, $value);
    }

    foreach ($this->methods as $method) {
      $args = $this->resolveArguments($method[1]);
      $reflectionMethod = $reflection->getMethod($method[0]);
      /* HH_IGNORE_ERROR[2049] */
      /* HH_IGNORE_ERROR[4107] */
      $reflectionMethod->invokeArgs($object, varray($args));
    }

    if (null !== $this->callback) {
      $callback = $this->callback;
      $callback($object);
    }
  }
}
