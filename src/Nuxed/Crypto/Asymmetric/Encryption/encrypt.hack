namespace Nuxed\Crypto\Asymmetric\Encryption;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Symmetric;

/**
 * Encrypt a string using asymmetric cryptography
 * Wraps Symmetric\Encryption\encrypt()
 */
function encrypt(
  Crypto\HiddenString $plaintext,
  Secret\PrivateSecret $privateSecret,
  Secret\PublicSecret $publicSecret,
  string $additionalData = '',
): string {
  return Symmetric\Encryption\encrypt(
    $plaintext,
    new Symmetric\Encryption\Secret(
      Secret::shared($privateSecret, $publicSecret),
    ),
    $additionalData,
  );
}
