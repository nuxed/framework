namespace Nuxed\Asset;

use namespace HH\Lib\Str;
use type Nuxed\Asset\Context\ContextInterface;
use type Nuxed\Asset\VersionStrategy\VersionStrategyInterface;

/**
 * Package that adds a base path to asset URLs in addition to a version.
 *
 * In addition to the provided base path, this package also automatically
 * prepends the current request base path if a Context is available to
 * allow a website to be hosted easily under any given path under the Web
 * Server root directory.
 */
class PathPackage extends Package {
  private string $basePath;

  /**
   * @param string                   $basePath        The base path to be prepended to relative paths
   * @param VersionStrategyInterface $versionStrategy The version strategy
   * @param ContextInterface|null    $context         The context
   */
  public function __construct(
    string $basePath,
    VersionStrategyInterface $versionStrategy,
    ContextInterface $context = new Context\NullContext(),
  ) {
    parent::__construct($versionStrategy, $context);

    if ('' === $basePath) {
      $this->basePath = '/';
    } else {
      if ('/' !== $basePath[0]) {
        $basePath = '/'.$basePath;
      }

      $this->basePath = Str\trim_right($basePath, '/').'/';
    }
  }

  /**
   * {@inheritdoc}
   */
  <<__Override>>
  public function getUrl(string $path): string {
    if ($this->isAbsoluteUrl($path)) {
      return $path;
    }

    $versionedPath = $this->getVersionStrategy()->applyVersion($path);

    // if absolute or begins with /, we're done
    if (
      $this->isAbsoluteUrl($versionedPath) ||
      (!Str\is_empty($versionedPath) && Str\starts_with($versionedPath, '/'))
    ) {
      return $versionedPath;
    }

    return $this->getBasePath().Str\trim_left($versionedPath, '/');
  }

  /**
   * Returns the base path.
   *
   * @return string The base path
   */
  public function getBasePath(): string {
    return $this->getContext()->getBasePath().$this->basePath;
  }
}
