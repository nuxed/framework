namespace Nuxed\Http\Emitter;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Emitter;

class EmitterFactory
  implements Service\FactoryInterface<Emitter\EmitterInterface> {
  public function create(Container\ContainerInterface $_container): Emitter {
    return new Emitter();
  }
}
