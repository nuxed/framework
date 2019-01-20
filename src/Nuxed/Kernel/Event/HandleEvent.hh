<?hh // strict

namespace Nuxed\Kernel\Event;

use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Http\Message\ServerRequestInterface;

class HandleEvent implements EventInterface {
  public function __construct(public ServerRequestInterface $request) {}
}
