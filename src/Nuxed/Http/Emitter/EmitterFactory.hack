namespace Nuxed\Http\Emitter;

use namespace His\Container;
use namespace Nuxed\Contract\Service;
use namespace Nuxed\Contract\Http\Emitter;

final class EmitterFactory
  implements Service\FactoryInterface<Emitter\EmitterInterface> {
  public function create(Container\ContainerInterface $container): Emitter {
    if ($container->has(MaxBufferLength::class)) {
      return new Emitter($container->get(MaxBufferLength::class));
    }

    return new Emitter();
  }
}
