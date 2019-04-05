namespace Nuxed\Container;

interface ServiceProviderInterface {
  public function register(ContainerBuilder $builder): void;
}
