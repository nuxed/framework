namespace Nuxed\Container\Service;

use namespace Nuxed\Container;

class CallableFactoryDecorator<T> implements Container\IFactory<T> {
  public function __construct(
    private (function(Container\IServiceContainer): T) $call,
  ) {}

  public function create(Container\IServiceContainer $container): T {
    $call = $this->call;

    return $call($container);
  }
}
