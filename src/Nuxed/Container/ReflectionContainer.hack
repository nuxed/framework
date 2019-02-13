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
use function class_exists;
use function explode;

class ReflectionContainer
  implements ArgumentResolverInterface, ContainerInterface {
  use ArgumentResolverTrait;
  use ContainerAwareTrait;

  /**
  * Cache of reslutions.
  */
  protected dict<string, dynamic> $cache;

  public function __construct(protected bool $cacheResolutions = false) {
    $this->cache = dict[];
  }

  /**
   * {@inheritdoc}
   */
  public function get(string $id, dict<string, dynamic> $args = dict[]): dynamic {
    if ($this->cacheResolutions && C\contains_key($this->cache, $id)) {
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

    if ($construct is nonnull) {
      $args = $this->reflectArguments($construct, $args);
      $resolution = $reflector->newInstanceArgs($args);
    } else {
      $resolution = $reflector->newInstance();
    }

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
    /* HH_IGNORE_ERROR[2049] */
    /* HH_IGNORE_ERROR[4107] */
    $vargs = (Container<mixed> $c): varray<mixed> ==> \varray($c);

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

      return $reflection->invokeArgs(
        /* HH_IGNORE_ERROR[4110] */
        $callable[0],
        $vargs($this->reflectArguments($reflection, $args)),
      );
    }

    $reflection = new ReflectionFunction($callable);

    return $reflection->invokeArgs(
      $vargs($this->reflectArguments($reflection, $args)),
    );
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
