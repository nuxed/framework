namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Http;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;

class SessionExtension extends AbstractExtension {
  <<__Override>>
  public function pipe(MiddlewarePipeInterface $pipe): void {
    /*
     * Register the session middleware in the middleware pipeline.
     * This middleware register the 'session' attribute containing the
     * session implementation.
     */
    $pipe->pipe(
      Http\Server\lm(
        () ==> $this->getContainer()
          ->get(Http\Session\SessionMiddleware::class) as MiddlewareInterface,
      ),
      0x9100,
    );
  }
}
