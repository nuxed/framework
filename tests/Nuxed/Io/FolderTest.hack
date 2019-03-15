namespace Nuxed\Test\Io;

use namespace HH\Asio;
use namespace Nuxed\Io;
use namespace HH\Lib\C;
use namespace HH\Lib\Tuple;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class FolderTest extends HackTest {
  use NodeTestTrait;

  <<DataProvider('provideMissingNodes')>>
  public async function testCreate(Io\Folder $folder): Awaitable<void> {
    $ret = await $folder->create(0444);
    expect($ret)->toBeTrue();
    $permissions = $folder->permissions();
    expect($permissions)->toBeSame(0444);
  }

  <<DataProvider('provideNodes')>>
  public async function testCreateRetrunsFalseIfFolderExists(
    Io\Folder $folder,
  ): Awaitable<void> {
    expect($folder->exists())->toBeTrue();
    $ret = await $folder->create(0755);
    expect($ret)->toBeFalse();
  }

  <<DataProvider('provideNodes')>>
  public async function testCopy(Io\Folder $folder): Awaitable<void> {
    // create the target directory path.
    $target = static::createPath();
    // copy folder to the target directory.
    $copy = await $folder->copy($target, Io\OperationType::OVERWRITE, 0711);
    expect($copy)->toBeInstanceOf(Io\Folder::class);
    $copy as Io\Folder;
    expect($copy->exists())->toBeTrue();
    expect($copy->permissions())->toBeSame(0711);
  }

  <<DataProvider('provideNodes')>>
  public async function testCopyWithContent(
    Io\Folder $folder,
  ): Awaitable<void> {
    // create a file inside the folder.
    $file = await $folder->touch('foo.txt');
    $file as Io\File;
    await $file->write('bar');

    // create the target directory path.
    $target = static::createPath();
    // copy folder to the target directory.
    $copy = await $folder->copy($target);
    expect($copy)->toBeInstanceOf(Io\Folder::class);
    $copy as Io\Folder;

    expect($copy->exists())->toBeTrue();

    // read the files inside the copy.
    $content = await $copy->files();
    expect(C\count($content))->toBeSame(1);
    $copyFileContent = await C\firstx($content)->read();
    expect($copyFileContent)->toBeSame('bar');

    // delete the nodes we created.
    await Asio\v(vec[
      $copy->delete(),
      $file->delete(),
    ]);
  }

  <<DataProvider('provideNodes')>>
  public async function testCopyOverwrite(Io\Folder $folder): Awaitable<void> {
    $target = static::createFolder();
    await $target->touch('foo.txt');
    $targetSize = await $target->size();
    expect($targetSize)->toBeSame(1);
    $copy = await $folder->copy($target->path(), Io\OperationType::OVERWRITE);
    expect($copy?->exists())->toBeTrue();
    $copy as Io\Folder;
    list($folderSize, $copySize) =
      await Tuple\from_async($folder->size(), $copy->size());
    expect($copySize)->toNotBeSame($targetSize);
    expect($copySize)->toBeSame($folderSize);

  }

  public async function testCopyThrowsWithSkipOperationIfTargetExist(
    Io\Folder $folder,
  ): Awaitable<void> {

  }

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
