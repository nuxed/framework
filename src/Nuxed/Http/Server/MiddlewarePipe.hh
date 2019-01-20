<?hh // strict

namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Server\Exception;
use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Server\MiddlewarePipeInterface;
use type SplPriorityQueue;

/**
 * Pipe middleware like unix pipes.
 *
 * This class implements a pipeline of middleware, which can be attached using
 * the `pipe()` method, and is itself middleware.
 *
 * It creates an instance of `NextMiddlewareProcessor` internally, invoking it with the provided
 * request and response instances, passing the original request and the returned
 * response to the `$next` argument when complete.
 *
 * Inspired by Sencha Connect.
 *
 * @see https://github.com/senchalabs/connect
 */
class MiddlewarePipe implements MiddlewarePipeInterface {
  private SplPriorityQueue<MiddlewareInterface> $pipeline;

  public function __construct() {
    $this->pipeline = new SplPriorityQueue<MiddlewareInterface>();
  }

  public function __clone(): void {
    $this->pipeline = clone $this->pipeline;
  }

  /**
   * Attach middleware to the pipeline.
   */
  public function pipe(
    MiddlewareInterface $middleware,
    int $priority = 0,
  ): void {
    $this->pipeline->insert($middleware, $priority);
  }


  /**
   * Handle an incoming request.
   *
   * Attempts to handle an incoming request by doing the following:
   *
   * - Cloning itself, to produce a request handler.
   * - Dequeuing the first middleware in the cloned handler.
   * - Processing the first middleware using the request and the cloned handler.
   *
   * If the pipeline is empty at the time this method is invoked, it will
   * raise an exception.
   *
   * @throws Exception\EmptyPipelineException if no middleware is present in
   *     the instance in order to process the request.
   */
  public async function handle(
    ServerRequestInterface $request,
  ): Awaitable<ResponseInterface> {
    if (0 === $this->pipeline->count()) {
      throw Exception\EmptyPipelineException::forClass(static::class);
    }

    $next = clone $this;
    $middleware = $next->pipeline->extract();
    return await $middleware->process($request, $next);
  }

  /**
   * Middleware invocation.
   *
   * Executes the internal pipeline, passing $handler as the "final
   * handler" in cases when the pipeline exhausts itself.
   */
  public async function process(
    ServerRequestInterface $request,
    RequestHandlerInterface $handler,
  ): Awaitable<ResponseInterface> {
    $next = new __Private\NextMiddlewareProcessor($this->pipeline, $handler);
    return await $next->handle($request);
  }

  public function reset(): void {
    $this->pipeline = new SplPriorityQueue<MiddlewareInterface>();
  }
}
