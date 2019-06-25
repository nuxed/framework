namespace Nuxed\Crypto\Asymmetric\Authentication;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\{Binary, Exception};
use namespace Nuxed\Crypto\Asymmetric\Encryption;

/**
 * Decrypt a message, then verify its signature.
 */
function unlock(
  string $ciphertext,
  Secret\SignaturePrivateSecret $secret,
  Encryption\Secret\PrivateSecret $encSecret,
): Crypto\HiddenString {
  $senderPublicKey = $secret->derivePublicSecret();
  $senderEncKey = $senderPublicKey->toEncryptionSecret();
  $decrypted = Encryption\decrypt($ciphertext, $encSecret, $senderEncKey);
  $signature = Binary\slice(
    $decrypted->toString(),
    0,
    \SODIUM_CRYPTO_SIGN_BYTES,
  );
  $message = Binary\slice($decrypted->toString(), \SODIUM_CRYPTO_SIGN_BYTES);
  if (!verify($message, $senderPublicKey, $signature)) {
    throw new Exception\InvalidSignatureException(
      'Invalid signature for decrypted message',
    );
  }
  return new Crypto\HiddenString($message);
}
