namespace Nuxed\Http\Server\Exception;

interface IServerException extends IException {
  public function getStatusCode(): int;

  public function getHeaders(): KeyedContainer<string, Container<string>>;
}
