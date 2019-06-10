namespace Nuxed\Jwt\Signer;

use namespace Nuxed\Jwt;

final class None implements Jwt\ISigner {
  /**
   * {@inhertdoc}
   */
  public function getAlgorithmId(): string {
    return 'none';
  }

  /**
   * {@inhertdoc}
   */
  public function sign(string $_payload, Key $_key): string {
    return '';
  }

  /**
   * {@inhertdoc}
   */
  public function verify(string $expected, string $_payload, Key $_key): bool {
    return $expected === '';
  }
}
