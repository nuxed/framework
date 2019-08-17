namespace Nuxed\Http\Server\Exception;

abstract class ServerException extends RuntimeException implements IException {
  abstract public function getStatusCode(): int;

  abstract public function getHeaders(
  ): KeyedContainer<string, Container<string>>;
}
