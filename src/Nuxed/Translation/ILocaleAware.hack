namespace Nuxed\Translation;

interface ILocaleAware {
  /**
   * Sets the current locale.
   *
   * @throws Exception\InvalidArgumentException If the locale contains invalid characters
   */
  public function setLocale(string $locale): void;

  /**
   * Returns the current locale.
   */
  public function getLocale(): string;
}
