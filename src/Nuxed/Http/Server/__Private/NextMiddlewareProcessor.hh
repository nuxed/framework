<?hh // strict

namespace Nuxed\Http\Server\__Private;

use type Nuxed\Contract\Http\Message\ResponseInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;
use type SplPriorityQueue;

class NextMiddlewareProcessor implements RequestHandlerInterface {
  private SplPriorityQueue<MiddlewareInterface> $queue;

  public function __construct(
    SplPriorityQueue<MiddlewareInterface> $queue,
    private RequestHandlerInterface $handler,
  ) {
    $this->queue = clone $queue;
  }

  public function handle(ServerRequestInterface $request): ResponseInterface {
    if (0 === $this->queue->count()) {
      return $this->handler->handle($request);
    }

    $middleware = $this->queue->extract();

    return $middleware->process($request, $this);
  }
}
