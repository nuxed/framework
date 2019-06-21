namespace Nuxed\Crypto\Symmetric\Encryption;

use namespace Nuxed\Crypto;
use namespace HH\Lib\SecureRandom;
use namespace Nuxed\Crypto\Symmetric\Authentication;

/**
 * Encrypt a message using the Halite encryption protocol
 *
 * (Encrypt then MAC -- xsalsa20 then keyed-Blake2b)
 * You don't need to worry about chosen-ciphertext attacks.
 *
 * @see https://github.com/paragonie/halite
 * @see https://github.com/paragonie/halite/blob/master/doc/Primitives.md
 */
function encrypt(
  Crypto\HiddenString $plaintext,
  Secret $secret,
  string $additionalData = '',
): string {
  /**
   * @see https://github.com/paragonie/halite/blob/master/src/Halite.php#L43
   */
  $version = "\x31\x42\x04\x00";

  // Generate a nonce and HKDF salt:
  $nonce = SecureRandom\string(\SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
  $salt = SecureRandom\string(32);
  // Split our key into two keys: One for encryption, the other for
  // authentication. By using separate keys, we can reasonably dismiss
  // likely cross-protocol attacks.
  // This uses salted HKDF to split the keys, which is why we need the
  // salt in the first place.
  list($encKey, $authKey) = Secret\split($secret, $salt);
  // Encrypt our message with the encryption key:
  $encrypted = \sodium_crypto_stream_xor(
    $plaintext->toString(),
    $nonce,
    $encKey,
  );
  \sodium_memzero(&$encKey);
  // Calculate an authentication tag:

  $auth = Authentication\authenticate(
    $version.$salt.$nonce.$additionalData.$encrypted,
    new Authentication\Secret(new Crypto\HiddenString($authKey)),
  );

  \sodium_memzero(&$authKey);
  $message = $version.$salt.$nonce.$encrypted.$auth;
  // Wipe every superfluous piece of data from memory
  \sodium_memzero(&$nonce);
  \sodium_memzero(&$salt);
  \sodium_memzero(&$encrypted);
  \sodium_memzero(&$auth);
  return $message;
}
