namespace Nuxed\Crypto\Symmetric\Password;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Password;
use namespace Nuxed\Crypto\Symmetric\Encryption;

/**
 * Is this password hash stale ?
 */
function needs_rehash(
  string $stored,
  Encryption\Secret $secret,
  Crypto\SecurityLevel $level = Crypto\SecurityLevel::INTERACTIVE,
  string $additionalData = '',
): bool {
  $stored = Encryption\decrypt($stored, $secret, $additionalData);
  return Password\needs_rehash($stored->toString(), $level);
}
