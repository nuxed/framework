namespace Nuxed\Translation\Loader;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace Nuxed\Io;
use namespace Nuxed\Util\Json;
use namespace Facebook\TypeSpec;
use namespace Nuxed\Translation\Exception;

final class JsonFileLoader extends FileLoader {
  <<__Override>>
  public function loadResource(
    Io\Path $resoruce,
  ): KeyedContainer<string, mixed> {
    $file = Io\Node::load($resoruce) as Io\File;

    try {
      $contents = Asio\join($file->read());
      $messages = Json\decode($contents);
      return TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
        ->coerceType($messages ?? dict[]);
    } catch (Io\Exception\IException $e) {
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
