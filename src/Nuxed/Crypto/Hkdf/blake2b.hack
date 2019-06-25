namespace Nuxed\Crypto\Hkdf;

use namespace HH\Lib\Str;
use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\{Binary, Exception};

function blake2b(
  string $ikm,
  int $length,
  string $info = '',
  string $salt = '',
): string {
  // Sanity-check the desired output length.
  if ($length < 0 || $length > (255 * \SODIUM_CRYPTO_GENERICHASH_KEYBYTES)) {
    throw new Exception\InvalidDigestLengthException('Bad HKDF Digest Length');
  }
  // "If [salt] not provided, is set to a string of HashLen zeroes."
  if ('' === $salt) {
    $salt = Str\repeat("\x00", \SODIUM_CRYPTO_GENERICHASH_KEYBYTES);
  }
  // HKDF-Extract:
  // PRK = HMAC-Hash(salt, IKM)
  // The salt is the HMAC key.
  $prk = \sodium_crypto_generichash(
    $ikm,
    $salt,
    \SODIUM_CRYPTO_GENERICHASH_BYTES,
  );
  // HKDF-Expand:
  // This check is useless, but it serves as a reminder to the spec.
  if (Binary\length($prk) < \SODIUM_CRYPTO_GENERICHASH_KEYBYTES) {
    throw new Exception\RuntimeException('An unknown error has occurred');
  }
  // T(0) = ''
  $t = '';
  $last_block = '';
  for ($block_index = 1; Binary\length($t) < $length; ++$block_index) {
    // T(i) = HMAC-Hash(PRK, T(i-1) | info | 0x??)
    $last_block = \sodium_crypto_generichash(
      $last_block.$info.Crypto\Str\chr($block_index),
      $prk,
      \SODIUM_CRYPTO_GENERICHASH_BYTES,
    );
    // T = T(1) | T(2) | T(3) | ... | T(N)
    $t .= $last_block;
  }
  // ORM = first L octets of T
  $orm = Binary\slice($t, 0, $length);
  return $orm;
}
