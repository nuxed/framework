<?hh // strict

namespace Nuxed\Test\Container\Asset;

use type Nuxed\Contract\Container\ContainerAwareInterface;
use type Nuxed\Container\ContainerAwareTrait;

class BarContainerAware implements ContainerAwareInterface {
  use ContainerAwareTrait;

  protected mixed $something;

  public function setSomething(mixed $something): void {
    $this->something = $something;
  }
}
