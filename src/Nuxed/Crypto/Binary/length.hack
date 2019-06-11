namespace Nuxed\Crypto\Binary;

function length(string $str): int {
  return \mb_strlen($str, '8bit');
}
