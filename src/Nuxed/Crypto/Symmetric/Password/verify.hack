namespace Nuxed\Crypto\Symmetric\Password;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Symmetric\Encryption;

/**
 * verify a password.
 */
function verify(
  Crypto\HiddenString $password,
  string $stored,
  Encryption\Secret $secret,
  string $additionalData = '',
): bool {
  $stored = Encryption\decrypt($stored, $secret, $additionalData);
  return \sodium_crypto_pwhash_str_verify(
    $stored->toString(),
    $password->toString(),
  );
}
