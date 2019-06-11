namespace Nuxed\Crypto\Binary;

function slice(string $str, int $offset = 0, ?int $length = null): string {
  if ($length === 0) {
    return '';
  }

  return \mb_substr($str, $offset, $length, '8bit');
}
