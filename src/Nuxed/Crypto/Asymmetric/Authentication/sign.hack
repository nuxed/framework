namespace Nuxed\Crypto\Asymmetric\Authentication;

/**
 * Sign a message with our private key
 */
function sign(string $message, Secret\SignaturePrivateSecret $secret): string {
  return \sodium_crypto_sign_detached($message, $secret->toString());
}
