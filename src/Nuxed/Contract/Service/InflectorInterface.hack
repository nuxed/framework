namespace Nuxed\Contract\Service;

use namespace His\Container;

interface InflectorInterface<T> {
  public function inflect(
    T $service,
    Container\ContainerInterface $container,
  ): T;
}
