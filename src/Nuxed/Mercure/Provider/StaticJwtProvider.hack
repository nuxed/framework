namespace Nuxed\Mercure\Provider;

use namespace Nuxed\Mercure;

final class StaticJwtProvider implements Mercure\IJwtProvider {
  public function __construct(private string $jwt) {}

  public function getJwt(): string {
    return $this->jwt;
  }
}
