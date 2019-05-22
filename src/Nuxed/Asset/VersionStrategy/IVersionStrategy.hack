namespace Nuxed\Asset\VersionStrategy;

interface IVersionStrategy {
  /**
   * Returns the asset version for an asset.
   *
   * @param string $path A path
   *
   * @return string The version string
   */
  public function getVersion(string $path): string;

  /**
   * Applies version to the supplied path.
   *
   * @param string $path A path
   *
   * @return string The versionized path
   */
  public function applyVersion(string $path): string;
}
