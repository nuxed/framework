namespace Nuxed\Jwt\Signer\Hmac;

use namespace Nuxed\Jwt\Signer;

final class Sha256 extends Signer\Hmac {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithmId(): string {
    return 'HS256';
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithm(): string {
    return 'sha256';
  }
}
