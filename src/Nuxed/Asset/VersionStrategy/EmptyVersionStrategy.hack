namespace Nuxed\Asset\VersionStrategy;

/**
 * Disable version for all assets.
 */
class EmptyVersionStrategy implements IVersionStrategy {
  /**
   * {@inheritdoc}
   */
  public function getVersion(string $_path): string {
    return '';
  }

  /**
   * {@inheritdoc}
   */
  public function applyVersion(string $path): string {
    return $path;
  }
}
