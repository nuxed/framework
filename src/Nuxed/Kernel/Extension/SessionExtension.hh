<?hh // strict

namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Http\Session;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Http\Server\MiddlewareFactory;

class SessionExtension extends AbstractExtension {
  <<__Override>>
  public function pipe(
    MiddlewarePipeInterface $pipe,
    MiddlewareFactory $middlewares,
  ): void {
    /*
     * Register the session middleware in the middleware pipeline.
     * This middleware register the 'session' attribute containing the
     * session implementation.
     */
    $pipe->pipe(
      $middlewares->prepare(Session\SessionMiddleware::class),
      0x9100,
    );
  }
}
