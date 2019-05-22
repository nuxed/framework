namespace Nuxed\Http\Emitter;

use namespace Nuxed\Http\Message;

final class Emitter implements IEmitter {
  private IEmitter $sapi;
  private IEmitter $stream;

  public function __construct(MaxBufferLength $length = 8192) {
    $this->sapi = new SapiEmitter();
    $this->stream = new SapiStreamEmitter($length);
  }

  public function emit(Message\Response $response): Awaitable<bool> {
    if (
      !$response->hasHeader('Content-Disposition') &&
      !$response->hasHeader('Content-Range')
    ) {
      return $this->sapi->emit($response);
    }

    return $this->stream->emit($response);
  }
}
