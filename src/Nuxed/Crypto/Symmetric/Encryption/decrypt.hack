namespace Nuxed\Crypto\Symmetric\Encryption;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Exception;
use namespace Nuxed\Crypto\Symmetric\Authentication;

/**
 * Decrypt a message using the Halite encryption protocol
 *
 * @see https://github.com/paragonie/halite
 * @see https://github.com/paragonie/halite/blob/master/doc/Primitives.md
 */
function decrypt(
  string $ciphertext,
  Secret $secretKey,
  string $additionalData = '',
): Crypto\HiddenString {
  $pieces = unpack($ciphertext);
  $version = $pieces[0];
  /** @var string $salt */
  $salt = $pieces[1];
  /** @var string $nonce */
  $nonce = $pieces[2];
  /** @var string $encrypted */
  $encrypted = $pieces[3];
  /** @var string $auth */
  $auth = $pieces[4];
  // Split our key into two keys: One for encryption, the other for
  // authentication. By using separate keys, we can reasonably dismiss
  // likely cross-protocol attacks.
  // This uses salted HKDF to split the keys, which is why we need the
  // salt in the first place. */
  list($encKey, $authKey) = Secret\split($secretKey, $salt);
  // Check the MAC first
  if (
    !Authentication\verify(
      $version.$salt.$nonce.$additionalData.$encrypted,
      new Authentication\Secret(new Crypto\HiddenString($authKey)),
      $auth,
    )
  ) {
    throw new Exception\InvalidMessageException(
      'Invalid message authentication code',
    );
  }
  \sodium_memzero(&$salt);
  \sodium_memzero(&$authKey);
  // crypto_stream_xor() can be used to encrypt and decrypt
  $plaintext = \sodium_crypto_stream_xor($encrypted, $nonce, $encKey);
  \sodium_memzero(&$encrypted);
  \sodium_memzero(&$nonce);
  \sodium_memzero(&$encKey);
  return new Crypto\HiddenString($plaintext);
}
