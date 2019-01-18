<?hh // strict

namespace Nuxed\Asset\VersionStrategy;

use namespace HH\Lib\Str;
use namespace Nuxed\Io;
use namespace Nuxed\Lib;
use namespace Nuxed\Asset\Exception;

/**
 * Reads the versioned path of an asset from a JSON manifest file.
 *
 * For example, the manifest file might look like this:
 *     {
 *         "main.js": "main.abc123.js",
 *         "css/styles.css": "css/styles.555abc.css"
 *     }
 *
 * You could then ask for the version of "main.js" or "css/styles.css".
 */
class JsonManifestVersionStrategy implements VersionStrategyInterface {
  private Io\File $manifest;
  private ?KeyedContainer<string, string> $manifestData;

  /**
   * @param string $manifestPath Absolute path to the manifest file
   */
  public function __construct(string $manifestPath) {
    $this->manifest = new Io\File($manifestPath, false);
  }

  /**
   * With a manifest, we don't really know or care about what
   * the version is. Instead, this returns the path to the
   * versioned file.
   */
  public function getVersion(string $path): string {
    return $this->applyVersion($path);
  }

  public function applyVersion(string $path): string {
    return $this->getManifestPath($path) ?? $path;
  }

  private function getManifestPath(string $path): ?string {
    if (null === $this->manifestData) {
      if (!$this->manifest->exists()) {
        throw new Exception\RuntimeException(Str\format(
          'Asset manifest file "%s" does not exist.',
          $this->manifest->path(),
        ));
      }

      // UNSAFE
      $this->manifestData = Lib\Json::decode($this->manifest->read());
    }

    return idx($this->manifestData, $path, null);
  }
}
