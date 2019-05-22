namespace Nuxed\Crypto;

use namespace HH\Lib\Str;

class Crypto {
  const string NONCE_MESSAGE_SEPARATOR = '%';

  public function __construct(public string $secret) {}

  public function encrypt(string $message): string {
    try {
      $nonce = \random_bytes(\SODIUM_CRYPTO_SECRETBOX_NONCEBYTES);
      $ciphertext = \sodium_crypto_secretbox($message, $nonce, $this->secret);
      if ($ciphertext is string) {
        return \sodium_bin2hex($nonce).
          static::NONCE_MESSAGE_SEPARATOR.
          \sodium_bin2hex($ciphertext);
      }

      throw new Exception\EncryptionException('Failed to encrypt raw message');
    } catch (\Exception $e) {
      throw new Exception\EncryptionException(
        $e->getMessage(),
        $e->getCode(),
        $e,
      );
    }
  }

  public function decrypt(string $data): string {
    try {
      list($nonce, $ciphertext) = Str\split(
        $data,
        static::NONCE_MESSAGE_SEPARATOR,
        2,
      );
      $nonce = \sodium_hex2bin($nonce);
      $ciphertext = \sodium_hex2bin($ciphertext);
      $message = \sodium_crypto_secretbox_open(
        $ciphertext,
        $nonce,
        $this->secret,
      );
      if ($message is string) {
        return $message;
      }

      throw new Exception\DecryptionException('Failed to decrpyt ciphertext');
    } catch (\Exception $e) {
      throw new Exception\DecryptionException(
        $e->getMessage(),
        $e->getCode(),
        $e,
      );
    }
  }
}
