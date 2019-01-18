<?hh // strict

namespace Nuxed\Container\Argument;

use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use namespace HH\Lib\C;
use type Nuxed\Container\Exception\ContainerException;
use type Nuxed\Container\Exception\NotFoundException;
use type Nuxed\Container\ReflectionContainer;
use type Nuxed\Contract\Container\ContainerInterface;
use type ReflectionFunctionAbstract;
use type ReflectionParameter;

trait ArgumentResolverTrait {
  public function resolveArguments(vec<mixed> $arguments): vec<mixed> {
    $resolved = vec[];

    foreach ($arguments as $arg) {
      if ($arg instanceof RawArgumentInterface) {
        $resolved[] = $arg->getValue();
        continue;
      }

      if ($arg instanceof ClassNameArgumentInterface) {
        $arg = $arg->getValue();
      }

      if (!($arg is string)) {
        $resolved[] = $arg;
        continue;
      }

      $container = null;

      try {
        $container = $this->getContainer();
      } catch (ContainerException $e) {
        if ($this instanceof ReflectionContainer) {
          $container = $this;
        }
      }


      if (null !== $container && $container->has($arg)) {
        $arg = $container->get($arg);

        if ($arg instanceof RawArgumentInterface) {
          $arg = $arg->getValue();
        }

        $resolved[] = $arg;
        continue;
      }

      $resolved[] = $arg;
    }

    return $resolved;
  }

  public function reflectArguments(
    ReflectionFunctionAbstract $method,
    dict<string, mixed> $args = dict[],
  ): vec<mixed> {
    $parameters = $method->getParameters();
    $arguments = Vec\map($parameters, (ReflectionParameter $param) ==> {

      $name = $param->getName();
      $class = $param->getClass();

      if (C\contains_key($args, $name)) {
        return $args[$name];
      }

      if (null !== $class) {
        return $class->getName();
      }

      $type = $param->getType();
      if (null !== $type && !$type->isBuiltin()) {
        if ($type->allowsNull()) {
          return Str\slice((string)$type, 1);
        } else {
          return (string)$type;
        }
      }

      if ($param->isDefaultValueAvailable()) {
        return $param->getDefaultValue();
      }

      throw new NotFoundException(Str\format(
        'Unable to resolve a value for parameter (%s) in the function/method (%s)',
        $name,
        $method->getName(),
      ));
    });

    return $this->resolveArguments($arguments);
  }

  abstract public function getContainer(): ContainerInterface;
}
