<?hh // strict

namespace Nuxed\Asset\Context;

class NullContext implements ContextInterface {
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
