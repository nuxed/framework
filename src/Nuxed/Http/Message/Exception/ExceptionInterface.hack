namespace Nuxed\Http\Message\Exception;

/**
 * Marker interface for component-specific exceptions.
 */
<<__Sealed(
  RuntimeException::class,
  InvalidArgumentException::class,
  UnrecognizedProtocolVersionException::class,
)>>
interface ExceptionInterface {
}
