namespace Nuxed\Mercure;

interface IJwtProvider {
  public function getJwt(): string;
}
