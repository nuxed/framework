namespace Nuxed\Crypto\Base64\DotSlash\Ordered;

use namespace Nuxed\Crypto\_Private;

/**
 * Encode into Base64
 *
 * Base64 character set:
 *  [.-9]      [A-Z]      [a-z]
 *  0x2e-0x39, 0x41-0x5a, 0x61-0x7a
 */
function encode(string $src, bool $pad = true): string {
  return _Private\Base64DotSlashOrdered::encode($src, $pad);
}
