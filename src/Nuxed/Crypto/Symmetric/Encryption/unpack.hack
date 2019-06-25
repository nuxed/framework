namespace Nuxed\Crypto\Symmetric\Encryption;

use namespace Nuxed\Crypto\{Binary, Exception};

/**
 * Unpack ciphertext for decryption.
 */
function unpack(string $ciphertext): (string, string, string, string) {
  $length = Binary\length($ciphertext);
  // Fail fast on invalid messages
  if ($length < 32) {
    throw new Exception\InvalidMessageException('Message is too short');
  }
  // The salt is used for key splitting (via HKDF)
  $salt = Binary\slice($ciphertext, 0, 32);
  // This is the nonce (we authenticated it):
  $nonce = Binary\slice(
    $ciphertext,
    // 32:
    32,
    // 24:
    \SODIUM_CRYPTO_STREAM_NONCEBYTES,
  );
  // This is the crypto_stream_xor()ed ciphertext
  $encrypted = Binary\slice(
    $ciphertext,
    // 56:
    32 + \SODIUM_CRYPTO_STREAM_NONCEBYTES,
    // $length - 120
    $length -
      (
        32 + // 32
        \SODIUM_CRYPTO_STREAM_NONCEBYTES + // 56
        \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX // 120
      ),
  );
  // $auth is the last 32 bytes
  $auth = Binary\slice(
    $ciphertext,
    $length - \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
  );
  // We don't need this anymore.
  \sodium_memzero(&$ciphertext);
  // Now we return the pieces in a specific order:
  return tuple($salt, $nonce, $encrypted, $auth);
}
