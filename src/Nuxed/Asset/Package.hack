namespace Nuxed\Asset;

use namespace HH\Lib\Str;

/**
 * Basic package that adds a version to asset URLs.
 */
class Package implements IPackage {
  public function __construct(
    private VersionStrategy\IVersionStrategy $versionStrategy,
    private Context\IContext $context = new Context\NullContext(),
  ) {
  }

  /**
   * {@inheritdoc}
   */
  public function getVersion(string $path): string {
    return $this->versionStrategy->getVersion($path);
  }

  /**
   * {@inheritdoc}
   */
  public function getUrl(string $path): string {
    if ($this->isAbsoluteUrl($path)) {
      return $path;
    }

    return $this->versionStrategy->applyVersion($path);
  }

  protected function getContext(): Context\IContext {
    return $this->context;
  }

  protected function getVersionStrategy(): VersionStrategy\IVersionStrategy {
    return $this->versionStrategy;
  }

  protected function isAbsoluteUrl(string $url): bool {
    return Str\contains($url, '://') || Str\starts_with($url, '//');
  }
}
