namespace Nuxed\Asset;

interface IPackage {
  /**
   * Returns the asset version for an asset.
   *
   * @param string $path A path
   *
   * @return string The version string
   */
  public function getVersion(string $path): string;

  /**
   * Returns an absolute or root-relative public path.
   *
   * @param string $path A path
   *
   * @return string The public path
   */
  public function getUrl(string $path): string;
}
