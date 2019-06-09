namespace Nuxed\Jwt\Signer\Ecdsa;

use namespace Nuxed\Jwt\Signer;

final class Sha512 extends Signer\Ecdsa {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithmId(): string {
    return 'ES512';
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithm(): int {
    return \OPENSSL_ALGO_SHA512;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getKeyLength(): int {
    return 132;
  }
}
