namespace Nuxed\Jwt\Signer\Ecdsa;

use namespace Nuxed\Jwt\Signer;

final class Sha384 extends Signer\Ecdsa {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithmId(): string {
    return 'ES384';
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithm(): int {
    return \OPENSSL_ALGO_SHA384;
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getKeyLength(): int {
    return 96;
  }
}
