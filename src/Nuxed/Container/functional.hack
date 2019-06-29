namespace Nuxed\Container;

function factory<T>((function(IServiceContainer): T) $factory): IFactory<T> {
  return new Service\CallableFactoryDecorator<T>($factory);
}

function newable<<<__Newable>>T as Service\Newable>(
  classname<T> $service,
): Service\NewableFactoryDecorator<T> {
  return new Service\NewableFactoryDecorator<T>($service);
}

function inflector<T>(
  (function(T, IServiceContainer): T) $inflector,
): IInflector<T> {
  return new Service\CallableInflectorDecorator<T>($inflector);
}
