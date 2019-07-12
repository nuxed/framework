namespace Nuxed\Translation\Loader;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace Nuxed\Filesystem;
use namespace Nuxed\Util\Json;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Translation\Exception;

final class JsonFileLoader extends FileLoader {
  <<__Override>>
  public function loadResource(
    Filesystem\Path $resoruce,
  ): KeyedContainer<string, mixed> {
    $file = Filesystem\Node::load($resoruce) as Filesystem\File;

    try {
      $contents = Asio\join($file->read());
      $messages = Json\decode($contents);
      return TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
        ->coerceType($messages ?? dict[]);
    } catch (Filesystem\Exception\IException $e) {
      throw new Exception\InvalidResourceException(
        Str\format('Unable to load file (%s).', $resoruce->toString()),
        $e->getCode(),
        $e,
      );
    } catch (Json\Exception\JsonDecodeException $e) {
      throw new Exception\InvalidResourceException(
        Str\format('Error parsing json file (%s).', $resoruce->toString()),
        $e->getCode(),
        $e,
      );
    }
  }
}
