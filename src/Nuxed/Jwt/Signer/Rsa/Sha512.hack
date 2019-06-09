namespace Nuxed\Jwt\Signer\Rsa;

use namespace Nuxed\Jwt\Signer;

final class Sha512 extends Signer\Rsa {
  /**
   * {@inheritdoc}
   */
  public function getAlgorithmId(): string {
    return 'RS512';
  }

  /**
   * {@inheritdoc}
   */
  public function getAlgorithm(): int {
    return \OPENSSL_ALGO_SHA512;
  }
}
