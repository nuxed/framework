namespace Nuxed\Crypto\Str;

use namespace Nuxed\Crypto\Binary;

function copy(string $string): string {
  $length = Binary\length($string);
  $return = '';
  $chunk = $length >> 1;
  if ($chunk < 1) {
    $chunk = 1;
  }
  for ($i = 0; $i < $length; $i += $chunk) {
    $return .= Binary\slice($string, $i, $chunk);
  }
  return $return;
}
