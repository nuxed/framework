namespace Nuxed\Http\Server;

use namespace Nuxed\Http\Server\Exception;
use type Nuxed\Http\Message\{Response, ServerRequest};
use type SplPriorityQueue;

final class MiddlewareStack implements IMiddlewareStack {
  private SplPriorityQueue<IMiddleware> $stack;

  public function __construct() {
    $this->stack = new SplPriorityQueue<IMiddleware>();
  }

  public function __clone(): void {
    $this->stack = clone $this->stack;
  }

  /**
   * Attach middleware to the stack.
   */
  public function stack(IMiddleware $middleware, int $priority = 0): void {
    $this->stack->insert($middleware, $priority);
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
   * If the stack is empty at the time this method is invoked, it will
   * raise an exception.
   *
   * @throws Exception\EmptyStackException if no middleware is present in
   *     the instance in order to process the request.
   */
  public async function handle(ServerRequest $request): Awaitable<Response> {
    if (0 === $this->stack->count()) {
      throw Exception\EmptyStackException::forClass(static::class);
    }

    $next = clone $this;
    $middleware = $next->stack->extract();
    return await $middleware->process($request, $next);
  }

  /**
   * Middleware invocation.
   *
   * Executes the internal stack, passing $handler as the "final
   * handler" in cases when the stack exhausts itself.
   */
  public async function process(
    ServerRequest $request,
    IRequestHandler $handler,
  ): Awaitable<Response> {
    $next = new RequestHandler\NextMiddlewareProcessor($this->stack, $handler);
    return await $next->handle($request);
  }
}
