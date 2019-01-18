<?hh // strict

namespace Nuxed\Asset\Context;

class Context implements ContextInterface {
  public function __construct(private string $basePath, private bool $secure) {}

  /**
   * {@inheritdoc}
   */
  public function getBasePath(): string {
    return $this->basePath;
  }

  /**
   * {@inheritdoc}
   */
  public function isSecure(): bool {
    return $this->secure;
  }
}
