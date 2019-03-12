namespace Nuxed\Test\Io;

use namespace HH\Asio;
use namespace HH\Lib\PseudoRandom;
use namespace Nuxed\Io;
use type Facebook\HackTest\HackTest;

trait IoTestTrait {
  require extends HackTest;
  public static async function beforeFirstTestAsync(): Awaitable<void> {
    await static::temporaryFolder()->create();
  }

  public static async function afterLastTestAsync(): Awaitable<void> {
    $tmp = static::temporaryFolder();
    await $tmp->chmod(0777, true);
    await $tmp->delete();
  }

  protected static function temporaryFolder(): Io\Folder {
    return new Io\Folder(Io\Path::create(__DIR__.'/../../tmp'));
  }

  protected static function createPath(): Io\Path {
    $path = static::temporaryFolder()->path()->toString().
      PseudoRandom\string(32, 'qwertyuiopasdfghjklzxcvbnm123456789');
    return Io\Path::create($path);
  }

  protected static function createFile(): Io\File {
    return Asio\join(
      Io\File::temporary('io_file_', static::temporaryFolder()->path()),
    );
  }

  protected static function createFolder(): Io\Folder {
    return new Io\Folder(static::createPath(), true);
  }

  protected static function createSymlink(): Io\File {
    $file = static::createFile();
    $symlink = static::createPath();
    $file->symlink($symlink);
    return new Io\File($symlink);
  }
}
