namespace Nuxed\Http\Emitter\Exception;

final class EmitterException extends \RuntimeException implements IException {
  public static function forHeadersSent(): this {
    return new static('Unable to emit response; headers already sent');
  }

  public static function forOutputSent(): this {
    return new static(
      'Output has been emitted previously; cannot emit response',
    );
  }
}
