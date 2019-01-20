namespace Nuxed\Http\Message\__Private;

use namespace HH\Lib\C;
use function function_exists;

class ServerParametersMarshaler {
  public function marshale(
    KeyedContainer<string, mixed> $server,
  ): dict<string, mixed> {
    $dict = dict[];
    foreach ($server as $key => $value) {
      $dict[$key] = $value;
    }

    return $this->normalize($dict);
  }

  private function normalize(dict<string, mixed> $server): dict<string, mixed> {
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
