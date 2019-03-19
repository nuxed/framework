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
  public function testCreateRetrunsFalseIfFolderExists(
    Io\Folder $folder,
  ): void {
    expect(async () ==> {
      expect($folder->exists())->toBeTrue();
      await $folder->create();
    })->toThrow(Io\Exception\ExistingNodeException::class);
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

  <<DataProvider('provideMissingNodes')>>
  public function testCopyThrowsIfFolderDoesntExists(Io\Folder $missing): void {
    expect(async () ==> {
      await $missing->copy(static::createPath());
    })->toThrow(Io\Exception\MissingNodeException::class);
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

  <<DataProvider('provideExistingNodesPair')>>
  public async function testCopyOverwrite(
    Io\Folder $folder,
    Io\Folder $target,
  ): Awaitable<void> {
    await $target->touch('foo.txt');
    $targetSize = await $target->size();
    expect($targetSize)->toBeSame(1);
    $copy = await $folder->copy($target->path(), Io\OperationType::OVERWRITE);
    expect($copy->exists())->toBeTrue();
    $copy as Io\Folder;
    list($folderSize, $copySize) =
      await Tuple\from_async($folder->size(), $copy->size());
    expect($copySize)->toNotBeSame($targetSize);
    expect($copySize)->toBeSame($folderSize);
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testCopySkip(
    Io\Folder $folder,
    Io\Folder $target,
  ): Awaitable<void> {
    $foo = await $folder->touch('foo.txt');
    await $foo->write('foo');
    $bar = await $folder->touch('bar.txt');
    await $bar->write('bar');
    $baz = await $target->touch('foo.txt');
    await $baz->write('baz');

    list($folderSize, $targetSize) =
      await Tuple\from_async($folder->size(), $target->size());
    expect($folderSize)->toBeSame(2);
    expect($targetSize)->toBeSame(1);

    $copy = await $folder->copy($target->path(), Io\OperationType::SKIP);

    list($folderSize, $copySize) =
      await Tuple\from_async($folder->size(), $copy->size());
    expect($copySize)->toNotBeSame($targetSize);
    expect($copySize)->toBeSame($folderSize);

    $content = await $baz->read();
    expect($content)->toBeSame('baz');
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testCopyMerge(
    Io\Folder $folder,
    Io\Folder $target,
  ): Awaitable<void> {
    await Asio\v(vec[
      $folder->flush(),
      $target->flush(),
    ]);
    $foo = await $folder->touch('foo.txt');
    await $foo->write('foo');
    $bar = await $folder->touch('bar.txt');
    await $bar->write('bar');
    await $target->touch('hip.txt');
    await $target->touch('hop.txt');
    $baz = await $target->touch('foo.txt');
    await $baz->write('baz');

    list($folderSize, $targetSize) =
      await Tuple\from_async($folder->size(), $target->size());
    expect($folderSize)->toBeSame(2);
    expect($targetSize)->toBeSame(3);

    $copy = await $folder->copy($target->path(), Io\OperationType::MERGE);

    list($folderSize, $copySize) =
      await Tuple\from_async($folder->size(), $copy->size());
    expect($copySize)->toNotBeSame($targetSize);
    expect($copySize)->toBeSame(4);

    $content = await $baz->read();
    expect($content)->toBeSame('foo');
  }

  <<DataProvider('provideNodes')>>
  public async function testDelete(Io\Folder $folder): Awaitable<void> {
    expect($folder->exists())->toBeTrue();
    $ret = await $folder->delete();
    expect($ret)->toBeTrue();
    expect($folder->exists())->toBeFalse();
  }

  <<DataProvider('provideMissingNodes')>>
  public function testDeleteThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(async () ==> {
      expect($folder->exists())->toBeFalse();
      await $folder->delete();
    })->toThrow(Io\Exception\MissingNodeException::class);
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
