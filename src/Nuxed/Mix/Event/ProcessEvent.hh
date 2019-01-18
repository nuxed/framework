<?hh // strict

namespace Nuxed\Mix\Event;

use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Server\RequestHandlerInterface;

class ProcessEvent implements EventInterface {
  public function __construct(
    public ServerRequestInterface $request,
    public RequestHandlerInterface $handler,
  ) {}
}
