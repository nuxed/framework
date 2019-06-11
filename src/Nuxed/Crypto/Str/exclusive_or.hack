namespace Nuxed\Crypto\Str;

use namespace Nuxed\Crypto\Binary;
use namespace Nuxed\Crypto\Exception;

/**
 * Calculate A xor B, given two binary strings of the same length.
 */
function exclusive_or(string $right, string $left): string {
  $length = Binary\length($left);
  if ($length !== Binary\length($right)) {
    throw new Exception\InvalidArgumentException(
      'Both strings must be the same length',
    );
  }

  if ($length < 1) {
    return '';
  }

  $left = vec(disassemble($left));
  $right = vec(disassemble($right));
  $result = '';
  foreach ($left as $i => $c) {
    $result .= chr($left[$i] ^ $right[$i]);
  }

  return $result;
}
