namespace Nuxed\Container\Service;

use namespace Nuxed\Container;

class CallableInflectorDecorator<T> implements Container\IInflector<T> {
  public function __construct(
    private (function(T, Container\IServiceContainer): T) $call,
  ) {}

  public function inflect(
    T $service,
    Container\IServiceContainer $container,
  ): T {
    $call = $this->call;

    return $call($service, $container);
  }
}
