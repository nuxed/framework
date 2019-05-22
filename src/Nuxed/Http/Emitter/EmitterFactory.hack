namespace Nuxed\Http\Emitter;

use namespace Nuxed\Container;
use namespace Nuxed\Contract;

final class EmitterFactory implements Container\IFactory<IEmitter> {
  public function create(Container\IServiceContainer $container): Emitter {
    if ($container->has(MaxBufferLength::class)) {
      return new Emitter($container->get(MaxBufferLength::class));
    }

    return new Emitter();
  }
}
