namespace Nuxed\Http\Server\Exception;

<<__Sealed(
  InvalidMiddlewareException::class,
  EmptyStackException::class,
  RuntimeException::class,
)>>
interface IException {
  require extends \Exception;
}
