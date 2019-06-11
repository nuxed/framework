namespace Nuxed\Crypto\Hex;

use namespace Nuxed\Crypto\_Private;

/**
 * Convert a binary string into a hexadecimal string without cache-timing
 * leaks
 *
 * Hex ( Base16 ) character set:
 *  [0-9]      [a-f]
 *  0x30-0x39, 0x61-0x66
 */
function encode(string $binary): string {
  return _Private\Hex::encode($binary);
}

/**
 * Convert a binary string into a hexadecimal string without cache-timing
 * leaks, returning uppercase letters (as per RFC 4648)
 *
 * Hex ( Base16 ) character set:
 *  [0-9]      [A-F]
 *  0x30-0x39, 0x41-0x46
 */
function encode_upper(string $binary): string {
  return _Private\Hex::encodeUpper($binary);
}
