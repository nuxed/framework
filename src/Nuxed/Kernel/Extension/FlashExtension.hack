namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Http;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Http\Server\MiddlewareFactory;

class FlashExtension extends AbstractExtension {
  <<__Override>>
  public function pipe(
    MiddlewarePipeInterface $pipe,
    MiddlewareFactory $middlewares,
  ): void {
    /*
     * Register the flash middleware in the middleware pipeline.
     * This middleware register the 'flash' attribute containing the
     * flash implementation.
     */
    $pipe->pipe(
      $middlewares->prepare(Http\Flash\FlashMessagesMiddleware::class),
      0x9090,
    );
  }
}
