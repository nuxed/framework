namespace Nuxed\Http\Message\_Private;

use namespace HH\Lib\C;
use function function_exists;

final class ServerParametersMarshaler {
  public function marshale(
    KeyedContainer<string, mixed> $server,
  ): KeyedContainer<string, mixed> {
    $dict = dict[];
    foreach ($server as $key => $value) {
      $dict[$key] = $value;
    }

    return $this->normalize($dict);
  }

  private function normalize(
    KeyedContainer<string, mixed> $server,
  ): KeyedContainer<string, mixed> {
    $server = dict($server);
    if (C\contains_key($server, 'HTTP_AUTHORIZATION')) {
      return $server;
    }

    if (function_exists('apache_request_headers')) {
      $apacheRequestHeaders = (fun('apache_request_headers'))();

      if (C\contains_key($apacheRequestHeaders, 'authorization')) {
        $server['HTTP_AUTHORIZATION'] = $apacheRequestHeaders['authorization'];
      }

      if (C\contains_key($apacheRequestHeaders, 'Authorization')) {
        $server['HTTP_AUTHORIZATION'] = $apacheRequestHeaders['Authorization'];
      }

      if (C\contains_key($apacheRequestHeaders, 'AUTHORIZATION')) {
        $server['HTTP_AUTHORIZATION'] = $apacheRequestHeaders['AUTHORIZATION'];
      }
    }

    return $server;
  }
}
