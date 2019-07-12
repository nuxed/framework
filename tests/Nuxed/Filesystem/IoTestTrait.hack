namespace Nuxed\Test\Filesystem;

use namespace HH\Asio;
use namespace HH\Lib\PseudoRandom;
use namespace Nuxed\Filesystem;
use type Facebook\HackTest\HackTest;

trait IoTestTrait {
  require extends HackTest;
  public static async function beforeFirstTestAsync(): Awaitable<void> {
    $tmp = static::temporaryFolder();
    if (!$tmp->exists()) {
      await $tmp->create();
    }
  }

  public static async function afterLastTestAsync(): Awaitable<void> {
    $tmp = static::temporaryFolder();
    if ($tmp->exists()) {
      await $tmp->delete();
    }
  }

  protected static function temporaryFolder(): Filesystem\Folder {
    return new Filesystem\Folder(Filesystem\Path::create(__DIR__.'/../../tmp'));
  }

  protected static function createPath(): Filesystem\Path {
    $path = static::temporaryFolder()->path()->toString().
      '/'.
      PseudoRandom\string(32, 'qwertyuiopasdfghjklzxcvbnm123456789');
    return Filesystem\Path::create($path);
  }

  protected static function createFile(): Filesystem\File {
    return Asio\join(
      Filesystem\File::temporary('io_file_', static::temporaryFolder()->path()),
    );
  }

  protected static function createFolder(): Filesystem\Folder {
    return new Filesystem\Folder(static::createPath(), true);
  }

  protected static function createSymlink(): Filesystem\File {
    $file = static::createFile();
    $symlink = static::createPath();
    return Asio\join($file->symlink($symlink));
  }
}
