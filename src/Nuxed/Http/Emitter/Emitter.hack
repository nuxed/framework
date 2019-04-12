namespace Nuxed\Http\Emitter;

use namespace Nuxed\Contract\Http\Emitter;
use namespace Nuxed\Contract\Http\Message;

final class Emitter implements Emitter\EmitterInterface {
  private Emitter\EmitterInterface $sapi;
  private Emitter\EmitterInterface $stream;

  public function __construct(
    MaxBufferLength $length = 8192
  ) {
    $this->sapi = new SapiEmitter();
    $this->stream = new SapiStreamEmitter($length);
  }

  public function emit(
    Message\ResponseInterface $response
  ): Awaitable<bool> {
    if (!$response->hasHeader('Content-Disposition') && !$response->hasHeader('Content-Range')) {
      return $this->sapi->emit($response);
    }

    return $this->stream->emit($response);
  }
}
