namespace Nuxed\Crypto\Password;

use namespace Nuxed\Crypto;

/**
 * verify a password.
 */
function verify(Crypto\HiddenString $password, string $stored): bool {
  return \sodium_crypto_pwhash_str_verify($stored, $password->toString());
}
