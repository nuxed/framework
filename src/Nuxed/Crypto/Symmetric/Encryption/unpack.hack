namespace Nuxed\Crypto\Symmetric\Encryption;

use namespace Nuxed\Crypto\Binary;
use namespace Nuxed\Crypto\_Private;
use namespace Nuxed\Crypto\Exception;

/**
 * Unpack ciphertext for decryption.
 */
function unpack(string $ciphertext): (string, string, string, string, string) {
  $length = Binary\length($ciphertext);
  // Fail fast on invalid messages
  if ($length < _Private\VERSION_TAG_LEN) {
    throw new Exception\InvalidMessageException('Message is too short');
  }
  // The first 4 bytes are reserved for the version size
  $version = Binary\slice($ciphertext, 0, _Private\VERSION_TAG_LEN);
  if ($length < 124) {
    throw new Exception\InvalidMessageException('Message is too short');
  }
  // The salt is used for key splitting (via HKDF)
  $salt = Binary\slice($ciphertext, _Private\VERSION_TAG_LEN, 32);
  // This is the nonce (we authenticated it):
  $nonce = Binary\slice(
    $ciphertext,
    // 36:
    _Private\VERSION_TAG_LEN + 32,
    // 24:
    \SODIUM_CRYPTO_STREAM_NONCEBYTES,
  );
  // This is the crypto_stream_xor()ed ciphertext
  $encrypted = Binary\slice(
    $ciphertext,
    // 60:
    _Private\VERSION_TAG_LEN + 32 + \SODIUM_CRYPTO_STREAM_NONCEBYTES,
    // $length - 124
    $length -
      (
        _Private\VERSION_TAG_LEN + // 4
        32 + // 36
        \SODIUM_CRYPTO_STREAM_NONCEBYTES + // 60
        \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX // 124
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
  return tuple($version, $salt, $nonce, $encrypted, $auth);
}
