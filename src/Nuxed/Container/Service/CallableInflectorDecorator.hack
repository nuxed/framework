namespace Nuxed\Container\Service;

use namespace Nuxed\Contract\Service;
use type His\Container\ContainerInterface;

class CallableInflectorDecorator<T> implements Service\InflectorInterface<T> {
  public function __construct(
    private (function(T, ContainerInterface): T) $call,
  ) {}

  public function inflect(T $service, ContainerInterface $container): T {
    $call = $this->call;

    return $call($service, $container);
  }
}
