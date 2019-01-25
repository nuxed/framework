namespace Nuxed\Kernel\Extension;

use namespace Nuxed\Kernel\Handler;
use namespace Nuxed\Kernel\Middleware;
use namespace Nuxed\Http\Router\Middleware as Router;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type Nuxed\Http\Server\MiddlewareFactory;

class HttpExtension extends AbstractExtension {
  <<__Override>>
  public function pipe(
    MiddlewarePipeInterface $pipe,
    MiddlewareFactory $middlewares,
  ): void {
    /*
     *  The error handler should be the first (most outer) middleware to catch
     *  all Exceptions.
     */
    $pipe->pipe(
      $middlewares->prepare(Middleware\ErrorMiddleware::class),
      0x10000,
    );

    /*
     * Register the routing middleware in the middleware pipeline.
     * This middleware register the Nuxed\Router\RouteResult request attribute.
     */
    $pipe->pipe($middlewares->prepare(Router\RouteMiddleware::class), -0x9500);

    /*
     * The following handle routing failures for common conditions:
     * - HEAD request but no routes answer that method
     * - OPTIONS request but no routes answer that method
     * - method not allowed
     * Order here maters; the
     */
    $pipe->pipe(
      $middlewares->prepare(Router\ImplicitHeadMiddleware::class),
      -0x9600,
    );
    $pipe->pipe(
      $middlewares->prepare(Router\ImplicitOptionsMiddleware::class),
      -0x9700,
    );
    $pipe->pipe(
      $middlewares->prepare(Router\MethodNotAllowedMiddleware::class),
      -0x9800,
    );

    /*
     * Register the dispatch middleware in the middleware pipeline.
     */
    $pipe->pipe(
      $middlewares->prepare(Router\DispatchMiddleware::class),
      -0x09900,
    );

    /*
     * At this point, if no Response is returned by any middleware, the
     * NotFoundHandler kicks in; alternately, you can provide other fallback
     * middleware to execute.
     */
    $pipe->pipe(
      $middlewares->prepare(Handler\NotFoundHandler::class),
      -0x10000,
    );
  }
}
