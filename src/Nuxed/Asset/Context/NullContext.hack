namespace Nuxed\Asset\Context;

class NullContext implements IContext {
  /**
   * {@inheritdoc}
   */
  public function getBasePath(): string {
    return '';
  }

  /**
   * {@inheritdoc}
   */
  public function isSecure(): bool {
    return false;
  }
}
