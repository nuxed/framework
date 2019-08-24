namespace Nuxed\Http\Server;

/**
 * Stack middleware like unix pipes.
 *
 * This interface represents a stack of middleware, which can be attached using
 * the `stack()` method, and is itself middleware.
 *
 * It creates an instance of `NextMiddlewareProcessor` internally, invoking it with the provided
 * request and response instances, passing the original request and the returned
 * response to the `$next` argument when complete.
 *
 * Inspired by Sencha Connect.
 *
 * @see https://github.com/senchalabs/connect
 */
interface IMiddlewareStack extends IHandler, IMiddleware {
  /**
   * Attach middleware to the stack.
   */
  public function stack(IMiddleware $middleware, int $priority = 0): void;
}
