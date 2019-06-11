namespace Nuxed\Crypto\Hex;

use namespace Nuxed\Crypto\_Private;

/**
 * Convert a hexadecimal string into a binary string without cache-timing
 * leaks
 *
 * Hex ( Base16 ) character set:
 *  [0-9]      [a-f]      [A-F]
 *  0x30-0x39, 0x61-0x66, 0x41-0x46
 */
function decode(string $hex, bool $strictPadding = false): string {
  return _Private\Hex::decode($hex, $strictPadding);
}

/**
 * Convert a hexadecimal uppercase string into a binary string without cache-timing
 * leaks
 *
 * Hex ( Base16 ) character set:
 *  [0-9]      [A-F]
 *  0x30-0x39, 0x41-0x46
 *
 * Note: Hex\decode is capable of decoding uppercase hexadecimal strings,
 *    this function exists only for consistency.
 */
function decode_upper(string $hex, bool $strictPadding = false): string {
  return decode($hex, $strictPadding);
}
