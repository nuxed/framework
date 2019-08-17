namespace Nuxed\Http\Server\Exception;

use namespace Nuxed\Http\Message;

final class NotFoundException extends ServerException {
  <<__Override>>
  public function getStatusCode(): int {
    return Message\StatusCode::STATUS_NOT_FOUND;
  }

  <<__Override>>
  public function getHeaders(): KeyedContainer<string, Container<string>> {
    return dict[];
  }
}
