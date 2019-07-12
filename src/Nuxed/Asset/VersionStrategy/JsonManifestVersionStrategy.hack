namespace Nuxed\Asset\VersionStrategy;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace Nuxed\Filesystem;
use namespace Nuxed\Util\Json;
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
class JsonManifestVersionStrategy implements IVersionStrategy {
  const type TManifest = KeyedContainer<string, string>;
  private ?KeyedContainer<string, string> $manifestData;

  public function __construct(private Filesystem\File $manifest) {
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
    if ($this->manifestData is null) {
      if (!$this->manifest->exists()) {
        throw new Exception\RuntimeException(Str\format(
          'Asset manifest file "%s" does not exist.',
          $this->manifest->path()->toString(),
        ));
      }

      $this->manifestData = Json\structure(
        Asio\join($this->manifest->read()),
        type_structure($this, 'TManifest'),
      );
    }

    return idx($this->manifestData, $path, null);
  }
}
