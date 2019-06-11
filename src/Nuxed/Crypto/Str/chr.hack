namespace Nuxed\Crypto\Str;

/**
 * Convert an integer to a string (without cache-timing side-channels)
 */
function chr(int $chr): string {
  return \pack('C', $chr);
}
