namespace Nuxed\Translation\Reader;

use namespace Nuxed\Translation;

/**
 * TranslationReader reads translation messages from translation files.
 */
interface ITranslationReader {
  /**
   * Reads translation messages from a directory to the catalogue.
   */
  public function read(
    string $directory,
    Translation\MessageCatalogue $catalogue,
  ): void;
}
