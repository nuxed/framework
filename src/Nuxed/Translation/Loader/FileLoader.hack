namespace Nuxed\Translation\Loader;

use namespace Nuxed\{Filesystem, Translation};
use namespace HH\Lib\Str;
use namespace Nuxed\Translation\Exception;

abstract class FileLoader implements ILoader<string> {
  public function load(
    string $resource,
    string $locale,
    string $domain = 'messages',
  ): Translation\MessageCatalogue {
    $resource = Filesystem\Path::create($resource);
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
    Filesystem\Path $resource,
  ): KeyedContainer<string, mixed>;
}
