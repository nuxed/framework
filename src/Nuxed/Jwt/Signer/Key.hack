namespace Nuxed\Jwt\Signer;

final class Key {
  public function __construct(
    private string $content,
    private string $passphrase = '',
  ) {}

  public function getContent(): string {
    return $this->content;
  }

  public function getPassphrase(): string {
    return $this->passphrase;
  }
}
