namespace Nuxed\Translation;

interface ITranslatorBag {
  /**
   * Gets the catalogue by locale
   *
   * @throws Exception\InvalidArgumentException If the locale contains invalid characters
   */
  public function getCatalogue(?string $locale = null): MessageCatalogue;
}
