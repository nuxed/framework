namespace Nuxed\Test\Container\Asset;

use type Nuxed\Container\Argument\ArgumentResolverInterface;
use type Nuxed\Container\Argument\ArgumentResolverTrait;
use type Nuxed\Container\ContainerAwareTrait;

class QuxArgumentResolver implements ArgumentResolverInterface {
  use ContainerAwareTrait;
  use ArgumentResolverTrait;
}
