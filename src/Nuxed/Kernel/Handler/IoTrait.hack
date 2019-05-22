namespace Nuxed\Kernel\Handler;

use namespace Nuxed\Io;
use namespace Nuxed\Http\Server;

trait IoTrait {
  require implements Server\IRequestHandler;

  protected function file(
    string $path,
    bool $create = false,
    int $mode = 0777,
  ): Io\File {
    return new Io\File(Io\Path::create($path), $create, $mode);
  }

  protected function folder(
    string $path,
    bool $create = false,
    int $mode = 0777,
  ): Io\Folder {
    return new Io\Folder(Io\Path::create($path), $create, $mode);
  }
}
