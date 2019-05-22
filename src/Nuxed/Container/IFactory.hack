namespace Nuxed\Container;

interface IFactory<T> {
  public function create(IServiceContainer $container): T;
}
