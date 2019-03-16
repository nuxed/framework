namespace Nuxed\Test\Io;

use namespace HH\Asio;
use namespace Nuxed\Io;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class NodeTest extends HackTest {
  use IoTestTrait;

  <<DataProvider('provideLoadFileData')>>
  public function testLoadFile(Io\Path $file): void {
    expect(Io\Node::load($file))->toBeInstanceOf(Io\File::class);
  }

  public function provideLoadFileData(): Container<(Io\Path)> {
    return vec[
      tuple(Io\Path::create(__FILE__)),
      tuple(Io\Path::create(__DIR__.'/PathTest.hack')),
      tuple(static::createFile()->path()),
      tuple(static::createSymlink()->path()),
    ];
  }

  <<DataProvider('provideLoadFolderData')>>
  public function testLoadFolder(Io\Path $folder): void {
    expect(Io\Node::load($folder))->toBeInstanceOf(Io\Folder::class);
  }

  public function provideLoadFolderData(): Container<(Io\Path)> {
    return vec[
      tuple(Io\Path::create(__DIR__)),
      tuple(Io\Path::create(__DIR__.'/..')),
      tuple(static::createFolder()->path()),
      tuple(static::temporaryFolder()->path()),
    ];
  }

  public function testLoadThrowsForNonExistingPath(): void {
    expect(() ==> Io\Node::load(Io\Path::create('missing')))
      ->toThrow(
        Io\Exception\MissingNodeException::class,
        'Node (missing) doesn\'t exist.',
      );
  }

  <<DataProvider('provideDestoryData')>>
  public function testDestory(Io\Path $path): void {
    expect($path->exists())->toBeTrue();
    $result = Asio\join(Io\Node::destroy($path));
    expect($result)->toBeTrue();
    expect($path->exists())->toBeFalse();
  }

  public function provideDestoryData(): Container<(Io\Path)> {
    return vec[
      tuple(static::createFile()->path()),
      tuple(static::createFolder()->path()),
      tuple(static::createSymlink()->path()),
    ];
  }

  public function testDestoryThrowsForMissinPath(): void {
    expect(async () ==> {
      await Io\Node::destroy(static::createPath());
    })->toThrow(Io\Exception\MissingNodeException::class);
  }
}
