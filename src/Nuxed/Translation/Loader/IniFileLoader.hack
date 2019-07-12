namespace Nuxed\Translation\Loader;

use namespace Nuxed\Filesystem;
use namespace HH\Lib\Str;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Translation\Exception;

final class IniFileLoader extends FileLoader {
  <<__Override>>
  public function loadResource(
    Filesystem\Path $resource,
  ): KeyedContainer<string, mixed> {
    $messages = @\parse_ini_file($resource->toString(), true);
    if (false === $messages) {
      throw new Exception\InvalidResourceException(
        Str\format('Error parsing ini file (%s).', $resource->toString()),
      );
    }

    return TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
      ->coerceType($messages ?? dict[]);
  }
}
