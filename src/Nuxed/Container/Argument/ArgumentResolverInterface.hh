<?hh // strict

namespace Nuxed\Container\Argument;

use type Nuxed\Contract\Container\ContainerAwareInterface;
use type ReflectionFunctionAbstract;

interface ArgumentResolverInterface extends ContainerAwareInterface {
  /**
   * Resolve a vector of arguments to their concrete implementations.
   */
  public function resolveArguments(
    Container<mixed> $arguments,
  ): Container<mixed>;

  /**
   * Resolves the correct arguments to be passed to a method.
   */
  public function reflectArguments(
    ReflectionFunctionAbstract $method,
    KeyedContainer<string, mixed> $args,
  ): Container<mixed>;
}
