namespace Nuxed\Jwt\Signer\Hmac;

use namespace Nuxed\Jwt\Signer;

final class Sha384 extends Signer\Hmac {
  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithmId(): string {
    return 'HS384';
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getAlgorithm(): string {
    return 'sha384';
  }
}
