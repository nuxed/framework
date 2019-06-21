namespace Nuxed\Crypto\Asymmetric\Encryption;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Symmetric;

/**
 * Decrypt a ciphertext using asymmetric cryptography
 * Wraps Symmetric\Encryption\decrypt()
 */
function decrypt(
  string $ciphertext,
  Secret\PrivateSecret $privateSecret,
  Secret\PublicSecret $publicSecret,
  string $additionalData = '',
): Crypto\HiddenString {
  return Symmetric\Encryption\decrypt(
    $ciphertext,
    new Symmetric\Encryption\Secret(
      Secret::shared($privateSecret, $publicSecret),
    ),
    $additionalData,
  );
}
