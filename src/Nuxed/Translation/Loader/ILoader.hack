namespace Nuxed\Translation\Loader;

use namespace Nuxed\Translation;

interface ILoader<T> {
  /**
   * Loads a locale.
   *
   * @throws Translation\Exception\NotFoundResourceException when the resource cannot be found
   * @throws Translation\Exception\InvalidResourceException  when the resource cannot be loaded
   */
  public function load(
    T $resource,
    string $locale,
    string $domain = 'messages',
  ): Translation\MessageCatalogue;
}
