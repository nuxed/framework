namespace Nuxed\Jwt\Signer;

use namespace HH\Lib\C;
use namespace Nuxed\Jwt;
use namespace Nuxed\Jwt\Exception;

<<__Sealed(Ecdsa::class, Rsa::class)>>
abstract class OpenSSL implements Jwt\ISigner {
  final protected function createSignature(
    string $pem,
    string $passphrase,
    string $payload,
  ): string {
    $key = $this->getPrivateKey($pem, $passphrase);
    try {
      $signature = '';
      if (!\openssl_sign($payload, &$signature, $key, $this->getAlgorithm())) {
        throw new Exception\InvalidArgumentException(
          'There was an error while creating the signature: '.
          \openssl_error_string(),
        );
      }
      return $signature;
    } finally {
      \openssl_free_key($key);
    }
  }

  private function getPrivateKey(string $pem, string $passphrase): resource {
    $privateKey = \openssl_pkey_get_private($pem, $passphrase) as resource;
    $this->validateKey($privateKey);
    return $privateKey;
  }

  final protected function verifySignature(
    string $expected,
    string $payload,
    string $pem,
  ): bool {
    $key = $this->getPublicKey($pem);
    $result = \openssl_verify($payload, $expected, $key, $this->getAlgorithm());
    \openssl_free_key($key);
    return $result === 1;
  }

  private function getPublicKey(string $pem): resource {
    $publicKey = \openssl_pkey_get_public($pem) as resource;
    $this->validateKey($publicKey);
    return $publicKey;
  }

  /**
   * Raises an exception when the key type is not the expected type
   *
   * @throws Exception\InvalidArgumentException
   */
  private function validateKey(resource $key): void {
    $details = \openssl_pkey_get_details($key) as KeyedContainer<_, _>;

    if (
      !C\contains_key($details, 'key') ||
      $details['type'] !== $this->getKeyType()
    ) {
      throw new Exception\InvalidArgumentException(
        'This key is not compatible with this signer',
      );
    }
  }

  /**
   * Returns the type of key to be used to create/verify the signature (using OpenSSL constants)
   *
   * @internal
   */
  abstract public function getKeyType(): int;

  /**
   * Returns which algorithm to be used to create/verify the signature (using OpenSSL constants)
   *
   * @internal
   */
  abstract public function getAlgorithm(): int;
}
