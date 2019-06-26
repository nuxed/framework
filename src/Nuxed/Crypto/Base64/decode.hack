namespace Nuxed\Crypto\Base64;

use namespace Nuxed\Crypto\_Private;

/**
 * Decode from base64 into binary
 *
 * Base64 character set:
 *  [A-Z]      [a-z]      [0-9]      +     /
 *  0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2b, 0x2f
 */
function decode(string $src, bool $strictPadding = false): string {
  return _Private\Base64::decode($src, $strictPadding);
}
