namespace Nuxed\Crypto\Base64\DotSlash\Ordered;

use namespace Nuxed\Crypto\_Private;

/**
 * Decode from base64 into binary
 *
 * Base64 character set:
 *  [.-9]      [A-Z]      [a-z]
 *  0x2e-0x39, 0x41-0x5a, 0x61-0x7a
 */
function decode(string $src, bool $strictPadding = false): string {
  return _Private\Base64DotSlashOrdered::decode($src, $strictPadding);
}
