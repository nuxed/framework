namespace Nuxed\Crypto\Str;

use namespace Nuxed\Crypto\{Binary, Exception};

/**
 * Convert a character to an integer (without cache-timing side-channels)
 */
function ord(string $chr): int {
  if (1 !== Binary\length($chr)) {
    throw new Exception\InvalidArgumentException(
      'Must be a string with a length of 1',
    );
  }

  $result = \unpack('C', $chr);
  return (int)$result[1];
}
