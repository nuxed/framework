namespace Nuxed\Translation\Reader;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace Nuxed\Io;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Loader;

/**
 * TranslationReader reads translation messages from translation files.
 */
final class TranslationReader implements ITranslationReader {
  /**
   * Loaders used for import.
   */
  private dict<string, Loader\ILoader<string>> $loaders = dict[];

  /**
   * Adds a loader to the translation reader.
   */
  public function addLoader<T>(
    string $format,
    Loader\ILoader<string> $loader,
  ): this {
    $this->loaders[$format] = $loader;
    return $this;
  }

  /**
   * Reads translation messages from a directory to the catalogue.
   */
  public function read(
    string $directory,
    Translation\MessageCatalogue $catalogue,
  ): void {
    try {
      $folder = Io\Node::load($directory) as Io\Folder;
    } catch (\Throwable $e) {
      return;
    }

    $files = Asio\join(Asio\wrap($folder->files(false, true)));
    if ($files->isFailed()) {
      return;
    } else {
      $files = $files->getResult();
    }

    foreach ($this->loaders as $format => $loader) {
      $extension = Str\format('.%s.%s', $catalogue->getLocale(), $format);
      foreach ($files as $file) {
        $basename = $file->path()->basename();
        if (Str\ends_with($basename, $extension)) {
          $domain = Str\strip_suffix($basename, $extension);
          $catalogue->addCatalogue(
            $loader->load(
              $file->path()->toString(),
              $catalogue->getLocale(),
              $domain,
            ),
          );
        }
      }
    }
  }
}
