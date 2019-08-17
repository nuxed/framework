namespace Nuxed\Test\Filesystem;

use namespace HH\Asio;
use namespace Nuxed\Filesystem;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class NodeTest extends HackTest {
  use IoTestTrait;

  <<DataProvider('provideLoadFileData')>>
  public function testLoadFile(Filesystem\Path $file): void {
    expect(Filesystem\Node::load($file))->toBeInstanceOf(
      Filesystem\File::class,
    );
  }

  public function provideLoadFileData(): Container<(Filesystem\Path)> {
    return vec[
      tuple(Filesystem\Path::create(__FILE__)),
      tuple(Filesystem\Path::create(__DIR__.'/PathTest.hack')),
      tuple(static::createFile()->path()),
      tuple(static::createSymlink()->path()),
    ];
  }

  <<DataProvider('provideLoadFolderData')>>
  public function testLoadFolder(Filesystem\Path $folder): void {
    expect(Filesystem\Node::load($folder))->toBeInstanceOf(
      Filesystem\Folder::class,
    );
  }

  public function provideLoadFolderData(): Container<(Filesystem\Path)> {
    return vec[
      tuple(Filesystem\Path::create(__DIR__)),
      tuple(Filesystem\Path::create(__DIR__.'/..')),
      tuple(static::createFolder()->path()),
      tuple(static::temporaryFolder()->path()),
    ];
  }

  public function testLoadThrowsForNonExistingPath(): void {
    expect(() ==> Filesystem\Node::load(Filesystem\Path::create('missing')))
      ->toThrow(
        Filesystem\Exception\MissingNodeException::class,
        'Node (missing) doesn\'t exist.',
      );
  }

  <<DataProvider('provideDestoryData')>>
  public function testDestory(Filesystem\Path $path): void {
    expect($path->exists())->toBeTrue();
    $result = Asio\join(Filesystem\Node::destroy($path));
    expect($result)->toBeTrue();
    expect($path->exists())->toBeFalse();
  }

  public function provideDestoryData(): Container<(Filesystem\Path)> {
    return vec[
      tuple(static::createFile()->path()),
      tuple(static::createFolder()->path()),
      tuple(static::createSymlink()->path()),
    ];
  }

  public function testDestoryThrowsForMissinPath(): void {
    expect(async () ==> {
      await Filesystem\Node::destroy(static::createPath());
    })->toThrow(Filesystem\Exception\MissingNodeException::class);
  }
}
