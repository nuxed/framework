<?hh // strict

namespace Nuxed\Kernel\Event;

use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;
use type Nuxed\Contract\Http\Message\ResponseInterface;

class TerminateEvent implements EventInterface {
  public function __construct(
    public ServerRequestInterface $request,
    public ResponseInterface $response,
  ) {}
}
