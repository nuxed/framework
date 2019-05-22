namespace Nuxed\Asset;

use namespace HH\Lib\Str;
use type Nuxed\Asset\Context\IContext;
use type Nuxed\Asset\Context\NullContext;
use type Nuxed\Asset\VersionStrategy\IVersionStrategy;

/**
 * Basic package that adds a version to asset URLs.
 */
class Package implements IPackage {
  public function __construct(
    private IVersionStrategy $versionStrategy,
    private IContext $context = new NullContext(),
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

  protected function getContext(): IContext {
    return $this->context;
  }

  protected function getVersionStrategy(): IVersionStrategy {
    return $this->versionStrategy;
  }

  protected function isAbsoluteUrl(string $url): bool {
    return Str\contains($url, '://') || Str\starts_with($url, '//');
  }
}
