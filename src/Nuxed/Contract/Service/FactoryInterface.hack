namespace Nuxed\Contract\Service;

use namespace His\Container;

interface FactoryInterface<T> {
  public function create(Container\ContainerInterface $container): T;
}
