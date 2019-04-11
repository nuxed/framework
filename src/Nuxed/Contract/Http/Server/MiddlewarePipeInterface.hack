namespace Nuxed\Contract\Http\Server;

/**
 * Pipe middleware like unix pipes.
 *
 * This class implements a pipeline of middleware, which can be attached using
 * the `pipe()` method, and is itself middleware.
 */
interface MiddlewarePipeInterface
  extends MiddlewareInterface, RequestHandlerInterface {
  public function pipe(
    MiddlewareInterface $middleware,
    int $priority = 0,
  ): void;
}
