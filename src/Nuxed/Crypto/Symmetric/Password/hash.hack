namespace Nuxed\Crypto\Symmetric\Password;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Password;
use namespace Nuxed\Crypto\Symmetric\Encryption;

/**
 * Hash then encrypt a password
 */
function hash(
  Crypto\HiddenString $password,
  Encryption\Secret $secret,
  Crypto\SecurityLevel $level = Crypto\SecurityLevel::INTERACTIVE,
  string $additionalData = '',
): string {
  $hash = Password\hash($password, $level);
  return Encryption\encrypt(
    new Crypto\HiddenString($hash),
    $secret,
    $additionalData,
  );
}
