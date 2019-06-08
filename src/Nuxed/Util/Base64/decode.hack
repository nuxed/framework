namespace Nuxed\Util\Base64;

use namespace HH\Lib\Str;

function decode(string $data): string {
  $paddingLength = 4;
  $remainder = Str\length($data) % $paddingLength;
  if ($remainder !== 0) {
    $data .= Str\repeat('=', $paddingLength - $remainder);
  }
  $decodedContent = \base64_decode(\strtr($data, '-_', '+/'), true);

  if (!$decodedContent is string) {
    throw new \Exception(
      'Error while decoding from Base64: invalid characters used',
    );
  }
  return $decodedContent;
}
