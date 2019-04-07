namespace Nuxed\Container;

use type Nuxed\Contract\Service\FactoryInterface;
use type Nuxed\Contract\Service\InflectorInterface;
use type His\Container\ContainerInterface;

function factory<T>(
  (function(ContainerInterface): T) $factory,
): FactoryInterface<T> {
  return new Service\CallableFactoryDecorator($factory);
}

function inflector<T>(
  (function(T, ContainerInterface): T) $inflector,
): InflectorInterface<T> {
  return new Service\CallableInflectorDecorator($inflector);
}
