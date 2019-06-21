namespace Nuxed\Crypto\Password;

use namespace Nuxed\Crypto;

/**
 * Hash the given password, and return hash string.
 */
function hash(
  Crypto\HiddenString $password,
  Crypto\SecurityLevel $level = Crypto\SecurityLevel::INTERACTIVE,
): string {
  list($opslimit, $memlimit) = Crypto\kdf_limits($level);
  return \sodium_crypto_pwhash_str($password->toString(), $opslimit, $memlimit);
}
