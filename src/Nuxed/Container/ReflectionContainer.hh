<?hh // strict

namespace Nuxed\Container;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use type Nuxed\Container\Argument\ArgumentResolverInterface;
use type Nuxed\Container\Argument\ArgumentResolverTrait;
use type Nuxed\Container\Exception\NotFoundException;
use type Nuxed\Contract\Container\ContainerInterface;
use type ReflectionClass;
use type ReflectionFunction;
use type ReflectionMethod;
use function is_object;
use function class_exists;
use function explode;

class ReflectionContainer
  implements ArgumentResolverInterface, ContainerInterface {
  use ArgumentResolverTrait;
  use ContainerAwareTrait;

  /**
  * Cache of reslutions.
  */
  protected dict<string, mixed> $cache;

  public function __construct(protected bool $cacheResolutions = false) {
    $this->cache = dict[];
  }

  /**
   * {@inheritdoc}
   */
  public function get(string $id, dict<string, mixed> $args = dict[]): mixed {
    if ($this->cacheResolutions === true && C\contains_key($this->cache, $id)) {
      return $this->cache[$id];
    }

    if (!$this->has($id)) {
      throw new NotFoundException(
        Str\format(
          'Alias (%s) is not an existing class and therefore cannot be resolved',
          $id,
        ),
      );
    }

    $reflector = new ReflectionClass($id);
    $construct = $reflector->getConstructor();

    $resolution = null === $construct
      ? $reflector->newInstance()
      : $reflector->newInstanceArgs($this->reflectArguments($construct, $args));

    if ($this->cacheResolutions) {
      $this->cache[$id] = $resolution;
    }

    return $resolution;
  }

  /**
   * {@inheritdoc}
   */
  public function has(string $id): bool {
    return class_exists($id);
  }

  /**
   * Invoke a callable via the container.
   *
   * @param callable $callable
   * @param dict<string, mixed>   $args
   *
   * @return mixed
   */
  public function call(
    mixed $callable,
    dict<string, mixed> $args = dict[],
  ): mixed {
    if (($callable is string) && Str\search($callable, '::') !== null) {
      $callable = explode('::', $callable);
    }

    if ($callable is KeyedContainer<_, _>) {
      /* HH_IGNORE_ERROR[4110] */
      if ($callable[0] is string) {
        /* HH_IGNORE_ERROR[4110] */
        /* HH_IGNORE_ERROR[4011] */
        $callable[0] = $this->getContainer()->get($callable[0]);
      }

      /* HH_IGNORE_ERROR[4110] */
      $reflection = new ReflectionMethod($callable[0], $callable[1]);

      if ($reflection->isStatic()) {
        /* HH_IGNORE_ERROR[4011] */
        $callable[0] = null;
      }


      $arguments = varray[];
      foreach ($this->reflectArguments($reflection, $args) as $arg) {
        $arguments[] = $arg;
      }


      return $reflection->invokeArgs(
        /* HH_IGNORE_ERROR[4110] */
        $callable[0],
        $arguments,
      );
    }

    if (is_object($callable)) {
      $reflection = new ReflectionMethod($callable, '__invoke');

      $arguments = varray[];
      foreach ($this->reflectArguments($reflection, $args) as $arg) {
        $arguments[] = $arg;
      }

      return $reflection->invokeArgs($callable, $arguments);
    }

    $reflection = new ReflectionFunction($callable);

    $arguments = varray[];
    foreach ($this->reflectArguments($reflection, $args) as $arg) {
      $arguments[] = $arg;
    }

    return $reflection->invokeArgs($arguments);
  }

  /**
   * Whether the container should default to caching resolutions and returning
   * the cache on following calls.
   *
   * @param boolean $option
   *
   * @return self
   */
  public function cacheResolutions(bool $option = true): ReflectionContainer {
    $this->cacheResolutions = $option;

    return $this;
  }

  public function reset(): void {
    $this->cache = dict[];
  }
}
