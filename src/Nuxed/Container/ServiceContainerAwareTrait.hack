namespace Nuxed\Container;

trait ServiceContainerAwareTrait implements IServiceContainerAware {
  public ?IServiceContainer $container = null;

  public function setServiceContainer(IServiceContainer $container): void {
    $this->container = $container;
  }

  public function hasServiceContainer(): bool {
    return $this->container is nonnull;
  }

  public function getServiceContainer(): IServiceContainer {
    return $this->container as nonnull;
  }
}
