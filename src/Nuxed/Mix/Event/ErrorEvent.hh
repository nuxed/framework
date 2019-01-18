<?hh // strict

namespace Nuxed\Mix\Event;

use namespace Nuxed\Contract\Http\Message;
use type Nuxed\Contract\Event\EventInterface;
use type Nuxed\Contract\Event\StoppableEventInterface;
use type Throwable;

class ErrorEvent implements EventInterface, StoppableEventInterface {
  public bool $handled = false;

  public ?Message\ResponseInterface $response;

  public function __construct(
    public Throwable $error,
    public Message\ServerRequestInterface $request,
  ) {}

  public function isPropagationStopped(): bool {
    return $this->response is nonnull;
  }
}
