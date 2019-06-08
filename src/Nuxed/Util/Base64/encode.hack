namespace Nuxed\Util\Base64;

use namespace HH\Lib\Str;

function encode(string $data): string {
  return Str\replace(\strtr(\base64_encode($data), '+/', '-_'), '=', '');
}
