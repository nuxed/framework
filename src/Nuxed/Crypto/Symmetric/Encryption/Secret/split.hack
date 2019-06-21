namespace Nuxed\Crypto\Symmetric\Encryption\Secret;

use namespace Nuxed\Crypto\Hkdf;
use namespace Nuxed\Crypto\Symmetric\Encryption;

/**
 * Split a key (using HKDF-BLAKE2b instead of HKDF-HMAC-*)
 */
function split(Encryption\Secret $master, string $salt): (string, string) {
  $binary = $master->toString();
  return tuple(
    Hkdf\blake2b(
      $binary,
      \SODIUM_CRYPTO_SECRETBOX_KEYBYTES,
      // consistent with paragonie/halite
      'Halite|EncryptionKey',
      $salt,
    ),
    Hkdf\blake2b(
      $binary,
      \SODIUM_CRYPTO_AUTH_KEYBYTES,
      // consistent with paragonie/halite
      'AuthenticationKeyFor_|Halite',
      $salt,
    ),
  );
}
