namespace Nuxed\Test\Io;

use namespace Nuxed\Io;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class FolderTest extends HackTest {
  use NodeTestTrait;

  public function provideNodes(): Container<(Io\Node)> {
    return vec[
      tuple(static::createFolder()),
      tuple(static::createFolder()),
      tuple(static::createFolder()),
    ];
  }

  public function provideMissingNodes(): Container<(Io\Node)> {
    return vec[
      tuple(new Io\Folder(static::createPath(), false)),
      tuple(new Io\Folder(static::createPath(), false)),
      tuple(new Io\Folder(static::createPath(), false)),
    ];
  }
}
