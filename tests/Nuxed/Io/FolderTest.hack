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
  public function testCreateThrowsIfFolderExists(Io\Folder $folder): void {
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
    list($folderSize, $copySize) = await Tuple\from_async(
      $folder->size(),
      $copy->size(),
    );
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

    list($folderSize, $targetSize) = await Tuple\from_async(
      $folder->size(),
      $target->size(),
    );
    expect($folderSize)->toBeSame(2);
    expect($targetSize)->toBeSame(1);

    $copy = await $folder->copy($target->path(), Io\OperationType::SKIP);

    list($folderSize, $copySize) = await Tuple\from_async(
      $folder->size(),
      $copy->size(),
    );
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

    list($folderSize, $targetSize) = await Tuple\from_async(
      $folder->size(),
      $target->size(),
    );
    expect($folderSize)->toBeSame(2);
    expect($targetSize)->toBeSame(3);

    $copy = await $folder->copy($target->path(), Io\OperationType::MERGE);

    list($folderSize, $copySize) = await Tuple\from_async(
      $folder->size(),
      $copy->size(),
    );
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

  <<DataProvider('provideNodes')>>
  public async function testFlush(Io\Folder $folder): Awaitable<void> {
    $foo = await $folder->touch('foo.txt');
    $bar = await $folder->mkdir('bar');
    $baz = await $bar->touch('baz.txt');
    expect($foo->exists())->toBeTrue();
    expect($bar->exists())->toBeTrue();
    expect($baz->exists())->toBeTrue();
    await $folder->flush();
    expect($foo->exists())->toBeFalse();
    expect($bar->exists())->toBeFalse();
    expect($baz->exists())->toBeFalse();
  }

  <<DataProvider('provideMissingNodes')>>
  public function testFlushThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(async () ==> {
      expect($folder->exists())->toBeFalse();
      await $folder->delete();
    })->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testFind(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    await Asio\v(vec[
      $folder->touch('foo.txt'),
      $folder->touch('bar.txt'),
      $folder->touch('baz.txt'),
      $folder->touch('foo.bar.txt'),
      $folder->touch('bar.baz.txt'),
      $folder->touch('foo.bar.baz.txt'),
      $folder->mkdir('foo'),
      $folder->mkdir('bar'),
      $folder->mkdir('baz'),
      $folder->mkdir('foobar'),
      $folder->mkdir('foobarbaz'),
      $folder->mkdir('barbaz'),
      $folder->touch('sub/a'),
      $folder->touch('sub/b'),
      $folder->touch('sub/c'),
    ]);

    $result = await $folder->find(re"/^foo([a-z\.])*/i");
    expect(C\count($result))->toBeSame(6);
    $result = await $folder->find(re"/^([a-z\.])*\.txt$/i", true);
    expect(C\count($result))->toBeSame(6);
    $result = await $folder->find(re"/.*/");
    expect(C\count($result))->toBeSame(13);
    $result = await $folder->find(re"/^([a-z\.])*\.baz.txt$/i");
    expect(C\count($result))->toBeSame(2);
    $result = await $folder->find(re"/.*bar.*/");
    expect(C\count($result))->toBeSame(8);
    $result = await $folder->find(re"/.*a(r|z).*/i", true);
    expect(C\count($result))->toBeSame(10);
    $result = await $folder->find(re"/.*a.*/");
    expect(C\count($result))->toBeSame(10);
    $result = await $folder->find(re"/.*a.*/", true);
    expect(C\count($result))->toBeSame(11);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testFindThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(async () ==> {
      expect($folder->exists())->toBeFalse();
      await $folder->find(re"/.*/");
    })->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testFindThrowsIfFolderIsUnreadable(
    Io\Folder $folder,
  ): Awaitable<void> {
    $this->markAsSkippedIfRoot();
    $permissions = $folder->permissions();
    await $folder->chmod(0111);
    expect(() ==> $folder->find(re"/.*/"))
      ->toThrow(Io\Exception\UnreadableNodeException::class);
    await $folder->chmod($permissions);
  }

  <<DataProvider('provideNodes')>>
  public async function testFolders(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    await $folder->mkdir('a/a/a');
    await Asio\v(vec[
      $folder->mkdir('b'),
      $folder->mkdir('c'),
      $folder->mkdir('a/b'),
      $folder->mkdir('a/c'),
      $folder->mkdir('a/a/b'),
      $folder->mkdir('a/a/c'),
    ]);

    $folders = await $folder->folders(true, true);
    expect(C\count($folders))->toBeSame(9);
    expect($folders)->toBeSortedBy(
      (Io\Node $a, Io\Node $b) ==> $a->path()->compare($b->path()) < 0,
    );
    $folders = await $folder->folders(false, false);
    expect(C\count($folders))->toBeSame(3);
  }

  <<DataProvider('provideNodes')>>
  public async function testFiles(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    await $folder->mkdir('a/a/a');
    await Asio\v(vec[
      $folder->touch('a.txt'),
      $folder->touch('b.txt'),
      $folder->touch('c.txt'),
      $folder->touch('a/a.txt'),
      $folder->touch('a/b.txt'),
      $folder->touch('a/c.txt'),
      $folder->touch('a/a/a.txt'),
      $folder->touch('a/a/b.txt'),
      $folder->touch('a/a/c.txt'),
    ]);

    $files = await $folder->files(true, true);
    expect(C\count($files))->toBeSame(9);
    expect($files)->toBeSortedBy(
      (Io\Node $a, Io\Node $b) ==> $a->path()->compare($b->path()) < 0,
    );
    $files = await $folder->files(false, false);
    expect(C\count($files))->toBeSame(3);
  }

  <<DataProvider('provideNodes')>>
  public async function testList(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    await $folder->mkdir('a/a/a');
    await Asio\v(vec[
      $folder->mkdir('b'),
      $folder->mkdir('c'),
      $folder->mkdir('a/b'),
      $folder->mkdir('a/c'),
      $folder->mkdir('a/a/b'),
      $folder->mkdir('a/a/c'),
      $folder->touch('a.txt'),
      $folder->touch('b.txt'),
      $folder->touch('c.txt'),
      $folder->touch('a/a.txt'),
      $folder->touch('a/b.txt'),
      $folder->touch('a/c.txt'),
      $folder->touch('a/a/a.txt'),
      $folder->touch('a/a/b.txt'),
      $folder->touch('a/a/c.txt'),
    ]);

    $nodes = await $folder->list(true, true);
    expect(C\count($nodes))->toBeSame(18);
    expect($nodes)->toBeSortedBy(
      (Io\Node $a, Io\Node $b) ==> $a->path()->compare($b->path()) < 0,
    );
    $nodes = await $folder->list(false, false, Io\Node::class);
    expect(C\count($nodes))->toBeSame(6);
    $files = await $folder->list(false, false, Io\File::class);
    expect(C\count($files))->toBeSame(3);
    $files = await $folder->list(true, true, Io\File::class);
    expect(C\count($files))->toBeSame(9);
    $folders = await $folder->list(false, false, Io\Folder::class);
    expect(C\count($folders))->toBeSame(3);
    $folders = await $folder->list(true, true, Io\Folder::class);
    expect(C\count($folders))->toBeSame(9);
  }

  <<DataProvider('provideNodes')>>
  public async function testListThrowsIfFolderIsUnreadable(
    Io\Folder $folder,
  ): Awaitable<void> {
    $this->markAsSkippedIfRoot();
    $permissions = $folder->permissions();
    await $folder->chmod(0111);
    expect(() ==> $folder->list())
      ->toThrow(Io\Exception\UnreadableNodeException::class);
    await $folder->chmod($permissions);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testListThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(() ==> $folder->list())
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testMove(Io\Folder $folder): Awaitable<void> {
    $target = static::createPath();
    expect($target->exists())->toBeFalse();
    await $folder->move($target, false);
    expect($target->exists())->toBeTrue();
    expect($target->compare($folder->path()))->toBeSame(0);
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testMoveOverride(
    Io\Folder $folder,
    Io\Folder $target,
  ): Awaitable<void> {
    $ret = await $folder->move($target->path(), true);
    expect($ret)->toBeTrue();
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testMoveThrowsIfTargetExists(
    Io\Folder $folder,
    Io\Folder $target,
  ): Awaitable<void> {
    expect(() ==> $folder->move($target->path(), false))
      ->toThrow(Io\Exception\ExistingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public async function testMoveThrowsIfFolderDoesntExist(
    Io\Folder $folder,
  ): Awaitable<void> {
    expect(() ==> $folder->move(Io\Path::create('dummy')))->toThrow(
      Io\Exception\MissingNodeException::class,
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testSize(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    $size = await $folder->size();
    expect($size)->toBeSame(0);
    await Asio\v(vec[
      $folder->touch('a'),
      $folder->touch('b'),
      $folder->touch('c'),
    ]);
    $size = await $folder->size();
    expect($size)->toBeSame(3);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testSizeThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(() ==> $folder->size())
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testTouch(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    $size = await $folder->size();
    expect($size)->toBeSame(0);
    await Asio\v(vec[
      $folder->touch('foo'),
      $folder->touch('bar'),
      $folder->touch('baz'),
    ]);
    $size = await $folder->size();
    expect($size)->toBeSame(3);
    $file = await $folder->touch('qux');
    expect($file->name())->toBeSame('qux');
    expect($file->parent()?->path()?->compare($folder->path()))->toBeSame(0);
  }

  <<DataProvider('provideNodes')>>
  public async function testTouchMode(Io\Folder $folder): Awaitable<void> {
    $this->markAsSkippedIfRoot();
    if ($folder->contains('foo')) {
      await $folder->remove('foo');
    }

    $file = await $folder->touch('foo', 0111);
    expect($file->readable())->toBeFalse();
    expect($file->writable())->toBeFalse();
    expect($file->executable())->toBeTrue();
    await $file->chmod(0755);

    if ($folder->contains('bar')) {
      await $folder->remove('bar');
    }

    $file = await $folder->touch('bar');
    expect($file->permissions())->toBeSame(0755);
    expect($file->readable())->toBeTrue();
    expect($file->writable())->toBeTrue();
    expect($file->executable())->toBeTrue();
  }

  <<DataProvider('provideNodes')>>
  public async function testTouchThrowsIfFolderIsUnwritable(
    Io\Folder $folder,
  ): Awaitable<void> {
    if ($folder->contains('foo')) {
      await $folder->remove('foo');
    }
    $this->markAsSkippedIfRoot();
    $permissions = $folder->permissions();
    await $folder->chmod(0111);
    expect(() ==> $folder->touch('foo'))
      ->toThrow(Io\Exception\UnwritableNodeException::class);
    await $folder->chmod($permissions);
  }

  <<DataProvider('provideNodes')>>
  public async function testTouchThrowsIfFileAlreadyExist(
    Io\Folder $folder,
  ): Awaitable<void> {
    if (!$folder->contains('foo')) {
      await $folder->touch('foo');
    }

    expect(() ==> $folder->touch('foo'))
      ->toThrow(Io\Exception\ExistingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testTouchThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(() ==> $folder->touch('foo'))
      ->toThrow(Io\Exception\MissingNodeException::class);
  }


  <<DataProvider('provideNodes')>>
  public async function testMkdir(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    $size = await $folder->size();
    expect($size)->toBeSame(0);
    await Asio\v(vec[
      $folder->mkdir('foo'),
      $folder->mkdir('bar'),
      $folder->mkdir('baz'),
    ]);
    $size = await $folder->size();
    expect($size)->toBeSame(3);
    $child = await $folder->mkdir('qux');
    expect($child->name())->toBeSame('qux');
    expect($child->parent()?->path()?->compare($folder->path()))->toBeSame(0);
  }

  <<DataProvider('provideNodes')>>
  public async function testMkdirMode(Io\Folder $folder): Awaitable<void> {
    if ($folder->contains('foo')) {
      await $folder->remove('foo');
    }
    $this->markAsSkippedIfRoot();

    $child = await $folder->mkdir('foo', 0111);
    expect($child->readable())->toBeFalse();
    expect($child->writable())->toBeFalse();
    expect($child->executable())->toBeTrue();
    // clean up
    await $child->chmod(0755);

    if ($folder->contains('bar')) {
      await $folder->remove('bar');
    }

    $child = await $folder->mkdir('bar');
    expect($child->permissions())->toBeSame(0755);
    expect($child->readable())->toBeTrue();
    expect($child->writable())->toBeTrue();
    expect($child->executable())->toBeTrue();
  }

  <<DataProvider('provideNodes')>>
  public async function testMkdirThrowsIfFolderIsUnwritable(
    Io\Folder $folder,
  ): Awaitable<void> {
    if ($folder->contains('foo')) {
      await $folder->remove('foo');
    }
    $this->markAsSkippedIfRoot();
    $permissions = $folder->permissions();
    await $folder->chmod(0111);
    expect(() ==> $folder->mkdir('foo'))
      ->toThrow(Io\Exception\UnwritableNodeException::class);
    await $folder->chmod($permissions);
  }

  <<DataProvider('provideNodes')>>
  public async function testMkdirThrowsIfFileAlreadyExist(
    Io\Folder $folder,
  ): Awaitable<void> {
    if (!$folder->contains('foo')) {
      await $folder->mkdir('foo');
    }

    expect(() ==> $folder->mkdir('foo'))
      ->toThrow(Io\Exception\ExistingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testMkdirThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(() ==> $folder->mkdir('foo'))
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testRemove(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    await Asio\v(vec[
      $folder->touch('foo'),
      $folder->touch('bar'),
      $folder->touch('baz'),
      $folder->mkdir('foobar'),
      $folder->mkdir('barbaz'),
      $folder->mkdir('bazfoo'),
    ]);
    $size = await $folder->size();
    expect($size)->toBeSame(6);

    await $folder->remove('foo');
    $size = await $folder->size();
    expect($size)->toBeSame(5);

    await $folder->remove('bar');
    $size = await $folder->size();
    expect($size)->toBeSame(4);

    await $folder->remove('baz');
    $size = await $folder->size();
    expect($size)->toBeSame(3);

    await $folder->remove('foobar');
    $size = await $folder->size();
    expect($size)->toBeSame(2);

    await $folder->remove('barbaz');
    $size = await $folder->size();
    expect($size)->toBeSame(1);

    await $folder->remove('bazfoo');
    $size = await $folder->size();
    expect($size)->toBeSame(0);
  }

  <<DataProvider('provideNodes')>>
  public async function testRemoveThrowsIfNodeDoesntExist(
    Io\Folder $folder,
  ): Awaitable<void> {
    await $folder->flush();
    expect(() ==> $folder->remove('foo'))
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testRemoveThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(() ==> $folder->remove('foo'))
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testContains(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    expect($folder->contains('foo'))->toBeFalse();
    await $folder->touch('foo');
    expect($folder->contains('foo'))->toBeTrue();
    expect($folder->contains('bar'))->toBeFalse();
    await $folder->mkdir('bar');
    expect($folder->contains('bar'))->toBeTrue();
    expect($folder->contains('baz'))->toBeFalse();
  }

  <<DataProvider('provideNodes')>>
  public async function testRead(Io\Folder $folder): Awaitable<void> {
    await $folder->flush();
    await $folder->touch('foo');
    $foo = await $folder->read('foo');
    expect($foo)->toBeInstanceOf(Io\File::class);
    await $folder->mkdir('bar');
    $bar = await $folder->read('bar');
    expect($bar)->toBeInstanceOf(Io\Folder::class);

    expect(() ==> $folder->read('bar', Io\File::class))
      ->toThrow(Io\Exception\InvalidPathException::class);
    expect(() ==> $folder->read('foo', Io\Folder::class))
      ->toThrow(Io\Exception\InvalidPathException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testReadThrowsIfNodeDoesntExist(
    Io\Folder $folder,
  ): Awaitable<void> {
    await $folder->flush();
    expect(() ==> $folder->read('foo'))
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testReadThrowsIfFolderDoesntExist(Io\Folder $folder): void {
    expect(() ==> $folder->read('foo'))
      ->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testChownRecursive(Io\Folder $folder): Awaitable<void> {
    $this->markAsSkippedIfNotRoot();
    await $folder->flush();
    $nodes = await Asio\v(vec[
      $folder->touch('foo'),
      $folder->touch('bar'),
      $folder->touch('baz'),
      $folder->mkdir('foobar'),
      $folder->mkdir('barbaz'),
      $folder->mkdir('bazfoo'),
    ]);
    await $folder->chown(655, true);
    expect($folder->owner())->toBeSame(655);
    foreach ($nodes as $node) {
      expect($node->owner())->toBeSame(655);
    }
  }

  <<DataProvider('provideNodes')>>
  public async function testChgroRecursive(Io\Folder $folder): Awaitable<void> {
    $this->markAsSkippedIfNotRoot();
    await $folder->flush();
    $nodes = await Asio\v(vec[
      $folder->touch('foo'),
      $folder->touch('bar'),
      $folder->touch('baz'),
      $folder->mkdir('foobar'),
      $folder->mkdir('barbaz'),
      $folder->mkdir('bazfoo'),
    ]);
    await $folder->chgrp(655, true);
    expect($folder->group())->toBeSame(655);
    foreach ($nodes as $node) {
      expect($node->group())->toBeSame(655);
    }
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
