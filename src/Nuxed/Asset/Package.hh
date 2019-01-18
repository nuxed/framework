<?hh // strict

namespace Nuxed\Asset;

use namespace HH\Lib\Str;
use type Nuxed\Asset\Context\ContextInterface;
use type Nuxed\Asset\Context\NullContext;
use type Nuxed\Asset\VersionStrategy\VersionStrategyInterface;

/**
 * Basic package that adds a version to asset URLs.
 */
class Package implements PackageInterface {
  public function __construct(
    private VersionStrategyInterface $versionStrategy,
    private ContextInterface $context = new NullContext(),
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

  protected function getContext(): ContextInterface {
    return $this->context;
  }

  protected function getVersionStrategy(): VersionStrategyInterface {
    return $this->versionStrategy;
  }

  protected function isAbsoluteUrl(string $url): bool {
    return Str\contains($url, '://') || Str\starts_with($url, '//');
  }
}
