<?hh // strict

namespace Nuxed\Http\Message\__Private;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use function strtr;

class HeadersMarshaler {
  public function marshal(
    dict<string, mixed> $server,
  ): dict<string, vec<string>> {
    $headers = dict[];

    $valid = (mixed $value): bool ==> {
      return
        $value is Container<_> ? C\count($value) > 0 : ((string)$value) !== '';
    };

    foreach ($server as $key => $value) {
      // Apache prefixes environment variables with REDIRECT_
      // if they are added by rewrite rules
      if (Str\search($key, 'REDIRECT_') === 0) {
        $key = Str\slice($key, 9);
        // We will not overwrite existing variables with the
        // prefixed versions, though
        if (C\contains_key($server, $key)) {
          continue;
        }
      }

      if (!$valid($value)) {
        continue;
      }


      if (Str\search($key, 'HTTP_') === 0) {
        $name = strtr(Str\lowercase(Str\slice($key, 5)), '_', '-');

        if (!$value is Container<_>) {
          $value = vec[(string)$value];
        }

        $val = vec[];
        foreach ($value as $v) {
          $val[] = (string)$v;
        }

        $headers[$name] = $val;
        continue;
      }

      if (Str\search($key, 'CONTENT_') === 0) {
        $name = 'content-'.Str\lowercase(Str\slice($key, 8));
        if (!$value is Container<_>) {
          $value = vec[(string)$value];
        }

        $value = vec[$value as string];
        $headers[$name] = $value;
        continue;
      }
    }

    return $headers;
  }
}
