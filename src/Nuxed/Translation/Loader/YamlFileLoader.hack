namespace Nuxed\Translation\Loader;

use namespace Nuxed\Io;
use namespace HH\Lib\Str;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Translation\Exception;

final class YamlFileLoader extends FileLoader {
  <<__Override>>
  public function loadResource(
    Io\Path $resource,
  ): KeyedContainer<string, mixed> {
    if (!\function_exists('yaml_parse_file')) {
      throw new Exception\LogicException(
        'Yaml extension is not loaded, make sure to enable zend compat.',
      );
    }

    /* HH_IGNORE_ERROR[2049] - yaml extension is not enabled by default */
    /* HH_IGNORE_ERROR[4107] - yaml extension is not enabled by default */
    $messages = @\yaml_parse_file($resource->toString(), true);
    if (false === $messages) {
      throw new Exception\InvalidResourceException(
        Str\format('Error parsing ini file (%s).', $resource->toString()),
      );
    }

    return TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
      ->coerceType($messages ?? dict[]);
  }
}
