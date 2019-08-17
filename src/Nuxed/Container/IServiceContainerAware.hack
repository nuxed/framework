namespace Nuxed\Container;

interface IServiceContainerAware {
  public function setServiceContainer(IServiceContainer $container): void;

  public function hasServiceContainer(): bool;

  public function getServiceContainer(): IServiceContainer;
}
