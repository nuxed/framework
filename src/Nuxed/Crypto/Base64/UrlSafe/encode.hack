
namespace Nuxed\Crypto\Base64\UrlSafe;

use namespace Nuxed\Crypto\_Private;

/**
 * Encode into Base64
 *
 * Base64 character set:
 *  [A-Z]      [a-z]      [0-9]      -     _
 *  0x41-0x5a, 0x61-0x7a, 0x30-0x39, 0x2d, 0x5f
 */
function encode(string $src, bool $pad = true): string {
  return _Private\Base64UrlSafe::encode($src, $pad);
}
