namespace Nuxed\Http\Message\__Private;

use namespace HH\Lib\C;

class MethodMarshaler {
  public function marshal(KeyedContainer<string, mixed> $server): string {
    return C\contains_key($server, 'REQUEST_METHOD')
      ? (string)$server['REQUEST_METHOD']
      : 'GET';
  }
}
