namespace Nuxed\Jwt\Signer\Rsa;

use namespace Nuxed\Jwt\Signer;

final class Sha384 extends Signer\Rsa {
  /**
   * {@inheritdoc}
   */
  public function getAlgorithmId(): string {
    return 'RS384';
  }

  /**
   * {@inheritdoc}
   */
  public function getAlgorithm(): int {
    return \OPENSSL_ALGO_SHA384;
  }
}
