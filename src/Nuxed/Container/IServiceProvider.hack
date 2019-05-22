namespace Nuxed\Container;

interface IServiceProvider {
  public function register(ContainerBuilder $builder): void;
}
