namespace Nuxed\Http\Server\Exception;

<<__Sealed(
  InvalidMiddlewareException::class,
  EmptyStackException::class,
  RuntimeException::class,
  ServerException::class,
)>>
interface IException {
  require extends \Exception;
}
