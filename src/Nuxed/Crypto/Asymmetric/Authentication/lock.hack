namespace Nuxed\Crypto\Asymmetric\Authentication;

use namespace Nuxed\Crypto;
use namespace Nuxed\Crypto\Asymmetric\Encryption;

function lock(
  Crypto\HiddenString $message,
  Secret\SignaturePrivateSecret $secret,
  Encryption\Secret\PublicSecret $recipientPublicKey,
): string {
  $signature = sign($message->toString(), $secret);
  $plaintext = new Crypto\HiddenString($signature.$message->toString());
  \sodium_memzero(&$signature);
  $myEncKey = $secret->toEncryptionSecret();
  return Encryption\encrypt($plaintext, $myEncKey, $recipientPublicKey);
}
