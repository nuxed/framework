namespace Nuxed\Container;

function factory<T>((function(IServiceContainer): T) $factory): IFactory<T> {
  return new Service\CallableFactoryDecorator($factory);
}

function inflector<T>(
  (function(T, IServiceContainer): T) $inflector,
): IInflector<T> {
  return new Service\CallableInflectorDecorator($inflector);
}
