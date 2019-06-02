namespace Nuxed\Translation\Loader;

use namespace Nuxed\Io;
use namespace HH\Lib\Str;
use namespace Nuxed\Translation;
use namespace Nuxed\Translation\Exception;

abstract class FileLoader implements ILoader<string> {
  public function load(
    \Stringish $resource,
    string $locale,
    string $domain = 'messages',
  ): Translation\MessageCatalogue {
    $resource = Io\Path::create($resource);
    if (!$resource->exists()) {
      throw new Exception\NotFoundResourceException(
        Str\format('File (%s) not found.', $resource->toString()),
      );
    }

    $resource = $this->loadResource($resource);
    return new TreeLoader() |> $$->load($resource, $locale, $domain);
  }

  /**
   * @return tree<arraykey, string>
   */
  abstract protected function loadResource(
    Io\Path $resource,
  ): KeyedContainer<string, mixed>;
}
