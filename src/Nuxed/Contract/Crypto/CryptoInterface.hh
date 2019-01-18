<?hh // strict

namespace Nuxed\Contract\Crypto;

interface CryptoInterface {
  /**
   * Encrypt the given raw message and return
   * the encrypted cipher
   *
   * @throws Exception\EncryptionExceptionInterface in case of an error.
   */
  public function encrypt(string $message): string;

  /**
   * Decrypt the given cipher and return
   * the raw message.
   *
   * @throws Exception\DecryptionExceptionInterface in case of an error.
   */
  public function decrypt(string $ciphertext): string;
}
