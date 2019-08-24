namespace Nuxed\Http\Server\Handler;

use namespace Nuxed\Http\{Message, Server};

class NextMiddlewareHandler implements Server\IHandler {
  private \SplPriorityQueue<Server\IMiddleware> $queue;

  public function __construct(
    \SplPriorityQueue<Server\IMiddleware> $queue,
    private Server\IHandler $handler,
  ) {
    $this->queue = clone $queue;
  }

  public async function handle(
    Message\ServerRequest $request,
  ): Awaitable<Message\Response> {
    if (0 === $this->queue->count()) {
      return await $this->handler->handle($request);
    }

    $middleware = $this->queue->extract();

    return await $middleware->process($request, $this);
  }
}
