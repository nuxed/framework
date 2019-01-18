<?hh // strict

namespace Nuxed\Mix\Event;

use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Http\Server\MiddlewareInterface;

class PipeEvent implements EventInterface {
  public function __construct(
    public MiddlewareInterface $middleware,
    public int $priority,
  ) {}
}
