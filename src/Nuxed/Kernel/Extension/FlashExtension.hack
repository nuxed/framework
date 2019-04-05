namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Http;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;

class FlashExtension extends AbstractExtension {
  <<__Override>>
  public function pipe(MiddlewarePipeInterface $pipe): void {
    $prepare = ($middleware) ==>
      Http\Server\lm(() ==> $this->container->get($middleware));

    /*
     * Register the flash middleware in the middleware pipeline.
     * This middleware register the 'flash' attribute containing the
     * flash implementation.
     */
    $pipe->pipe($prepare(Http\Flash\FlashMessagesMiddleware::class), 0x9090);
  }
}
