namespace Nuxed\Container\Service;

use namespace Nuxed\Contract\Service;
use type His\Container\ContainerInterface;

class CallableFactoryDecorator<T> implements Service\FactoryInterface<T> {
  public function __construct(
    private (function(ContainerInterface): T) $call,
  ) {}

  public function create(ContainerInterface $container): T {
    $call = $this->call;

    return $call($container);
  }
}
