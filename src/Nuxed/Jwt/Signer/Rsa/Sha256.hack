namespace Nuxed\Jwt\Signer\Rsa;

use namespace Nuxed\Jwt\Signer;

final class Sha256 extends Signer\Rsa {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithmId(): string {
    return 'RS256';
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithm(): int {
    return \OPENSSL_ALGO_SHA256;
  }
}
