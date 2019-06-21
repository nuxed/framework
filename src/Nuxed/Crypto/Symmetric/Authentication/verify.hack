namespace Nuxed\Crypto\Symmetric\Authentication;

use namespace Nuxed\Crypto\Str;
use namespace Nuxed\Crypto\Binary;
use namespace Nuxed\Crypto\Exception;

/**
 * Verify the authenticity of a message, given a shared MAC key
 */
function verify(string $message, Secret $secret, string $mac): bool {
  if (Binary\length($mac) !== \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX) {
    throw new Exception\InvalidSignatureException(
      'Message Authentication Code is not the correct length; is it encoded?',
    );
  }

  $calc = \sodium_crypto_generichash(
    $message,
    $secret->toString(),
    \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
  );
  $result = Str\equals($mac, $calc);
  \sodium_memzero(&$calc);
  return $result;
}
