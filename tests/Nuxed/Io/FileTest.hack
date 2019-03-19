namespace Nuxed\Test\Io;

use namespace HH\Asio;
use namespace Nuxed\Io;
use namespace HH\Lib\Str;
use namespace HH\Lib\Experimental\Filesystem;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;
use function microtime;

class FileTest extends HackTest {
  use NodeTestTrait;

  <<DataProvider('provideLoadData')>>
  public function testLoad(Io\Path $file): void {
    expect(Io\Node::load($file))->toBeInstanceOf(Io\File::class);
  }

  public function provideLoadData(): Container<(Io\Path)> {
    return vec[
      tuple(static::createFile()->path()),
      tuple(static::createFile()->path()),
      tuple(static::createFile()->path()),
      tuple(static::createSymlink()->path()),
    ];
  }

  <<DataProvider('provideTemporaryData')>>
  public async function testTemporary(
    string $prefix,
    Io\Path $dir,
  ): Awaitable<void> {
    $file = await Io\File::temporary($prefix, $dir);
    expect($file->path()->basename())->toContain($prefix);
    expect($file->path()->parent()->compare($dir))->toBeSame(0);
  }

  public function provideTemporaryData(): Container<(string, Io\Path)> {
    return vec[
      tuple('foo', static::createPath()),
      tuple('bar', static::createPath()),
      tuple('_baz-.', static::createPath()),
      tuple('_temporary_', static::temporaryFolder()->path()),
      tuple('baz', static::createFolder()->path()),
    ];
  }

  <<DataProvider('provideNodes')>>
  public async function testGetReadHandleThrowsForUnreadableFiles(
    Io\File $file
  ): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    await $file->chmod(0000);
    expect(async () ==> {
      await using $handle = $file->getReadHandle();
    })->toThrow(Io\Exception\UnreadableNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testGetWriteHandleThrowsForUnwritableFiles(
    Io\File $file
  ): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    // execute only
    await $file->chmod(0111);
    expect(async () ==> {
      await using $handle = $file->getWriteHandle();
    })->toThrow(Io\Exception\UnwritableNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testGetReadHandle(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foo');
    await using ($handle = $file->getReadHandle()) {
      $content = await $handle->readAsync();
      expect($content)->toBeSame('foo');
    }
  }

  <<DataProvider('provideNodes')>>
  public async function testGetWriteHandle(
    Io\File $file
  ): Awaitable<void> {
    await using ($handle = $file->getWriteHandle()) {
      await $handle->writeAsync('foo');
    }

    $content = await $file->read();
    expect($content)->toBeSame('foo');
  }

  <<DataProvider('provideCreateData')>>
  public async function testCreate(
    Io\Path $path,
    int $permissions,
  ): Awaitable<void> {
    $file = new Io\File($path, false);
    expect($path->exists())->toBeFalse();
    $ret = await $file->create($permissions);
    expect($ret)->toBeTrue();
    expect($path->exists())->toBeTrue();
    expect($file->permissions())->toBeSame($permissions);
  }

  public function provideCreateData(): Container<(Io\Path, int)> {
    return vec[
      tuple(static::createPath(), 0111),
      tuple(static::createPath(), 0222),
      tuple(static::createPath(), 0333),
      tuple(static::createPath(), 0444),
      tuple(static::createPath(), 0555),
      tuple(static::createPath(), 0666),
      tuple(static::createPath(), 0777),
      tuple(static::createPath(), 0744),
      tuple(static::createPath(), 0700),
    ];
  }

  public async function testCreateFailIfThereIsNoParentFolder(
  ): Awaitable<void> {
    $file = new Io\File('/foo.hack', false);
    $ret = await $file->create();
    expect($ret)->toBeFalse();
  }

  public async function testCreateCreatesTheParentFolderIfItDoesnExist(
  ): Awaitable<void> {
    $dir = static::createPath();
    $path = Io\Path::create($dir.'/foo.hack');
    expect($dir->exists())->toBeFalse();
    expect($path->exists())->toBeFalse();
    $file = new Io\File($path, false);
    $ret = await $file->create();
    expect($ret)->toBeTrue();
    expect($dir->exists())->toBeTrue();
    expect($path->exists())->toBeTrue();
  }

  <<DataProvider('provideNodes')>>
  public function testCreateThrowsIfFileAlreadyExist(
    Io\File $file
  ): void {
    expect(async () ==> {
      await $file->create();
    })->toThrow(Io\Exception\ExistingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public function testCopyThrowsIfFileDoesntExist(
    Io\File $file
  ): void {
    expect(async () ==> {
      await $file->delete();
      await $file->copy(static::createPath());
    })->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testCopyThrowsIfTargetExistWithSkipOperation(
    Io\File $file
  ): Awaitable<void> {
    expect(async () ==> {
      $target = static::createFile()->path();
      await $file->copy($target, Io\OperationType::SKIP);
    })->toThrow(Io\Exception\ExistingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public function testCopyThrowsWhenOperationFails(
    Io\File $file
  ): void {
    expect(async () ==> {
      $path = Io\Path::create('/foo/bar/baz.tmp');
      await $file->copy($path);
    })->toThrow(Io\Exception\RuntimeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testCopySetsTargetPermissionsTo0755ByDefault(
    Io\File $file
  ): Awaitable<void> {
    $path = static::createPath();
    $copy = await $file->copy($path);
    expect($copy)->toBeInstanceOf(Io\File::class);
    expect($copy->permissions())->toBeSame(0755);
  }

  <<DataProvider('provideNodes')>>
  public async function testCopyWithPermissions(
    Io\File $file
  ): Awaitable<void> {
    $path = static::createPath();
    $copy = await $file->copy($path, Io\OperationType::SKIP, 0733);
    expect($copy->permissions())->toBeSame(0733);
  }

  <<DataProvider('provideNodes')>>
  public async function testDelete(
    Io\File $file
  ): Awaitable<void> {
    $ret = await $file->delete();
    expect($ret)->toBeTrue();
  }

  <<DataProvider('provideMissingNodes')>>
  public function testDeleteThrowsIfFileDoesntExists(
    Io\File $file
  ): void {
    expect(async () ==> {
      await $file->delete();
    })->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideExtensionData')>>
  public function testExtension(Io\Path $path, ?string $expected): void {
    $file = new Io\File($path, false);
    expect($file->extension())->toBeSame($expected);
  }

  <<DataProvider('provideExtensionData')>>
  public function testExtensionIsProxyForPathExtension(
    Io\Path $path,
    ?string $_,
  ): void {
    $file = new Io\File($path, false);
    expect($file->extension())->toBeSame($path->extension());
  }

  public function provideExtensionData(): Container<(Io\Path, ?string)> {
    return vec[
      tuple(Io\Path::create(''), null),
      tuple(Io\Path::create('path/to/hhvm-4-main.hack'), 'hack'),
      tuple(Io\Path::create('path/to/hhvm-3-main.hh'), 'hh'),
      tuple(Io\Path::create('config.yml'), 'yml'),
      tuple(Io\Path::create('.gitignore'), 'gitignore'),
      tuple(Io\Path::create('example.foo.bar'), 'bar'),
    ];
  }

  public async function testMd5(): Awaitable<void> {
    $tmp = static::temporaryFolder();
    $file = new Io\File($tmp->path()->toString().'/foo.hack', true);

    await $file->write('namespace Tmp\Foo;'."\n\n");
    await $file->append('<<__EntryPoint>>'."\n");
    await $file->append('async function main(): Awaitable<void> {'."\n");
    await $file->append('  echo "hello, world!";'."\n");
    await $file->append('}'."\n");
    $hash = $file->md5();
    expect(Str\length($hash))->toBeSame(32);
    expect($hash)->toBeSame('c934dc050854790967503f84a39742c1');
  }

  public async function testMd5Raw(): Awaitable<void> {
    $tmp = static::temporaryFolder();
    $file = new Io\File($tmp->path()->toString().'/foo.hack', true);

    await $file->write('namespace Tmp\Foo;'."\n\n");
    await $file->append('<<__EntryPoint>>'."\n");
    await $file->append('async function main(): Awaitable<void> {'."\n");
    await $file->append('  echo "hello, world!";'."\n");
    await $file->append('}'."\n");
    $hash = $file->md5(true);
    expect(Str\length($hash))->toBeSame(16);
    expect(\bin2hex($hash))->toBeSame('c934dc050854790967503f84a39742c1');
  }

  <<DataProvider('provideMissingNodes')>>
  public function testMd5ThrowsFileDoesntExists(
    Io\File $file
  ): void {
    expect(() ==> {
      $file->md5();
    })->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideMimeTypeData')>>
  public function testMimeType(Io\Path $path, string $expected): void {
    $file = Io\Node::load($path) as Io\File;
    expect($file->mimeType())->toBeSame($expected);
  }

  public function provideMimeTypeData(): Container<(Io\Path, string)> {
    return vec[
      tuple(Io\Path::create(__DIR__.'/../../../.gitattributes'), 'text/plain'),
      tuple(
        Io\Path::create(__DIR__.'/../../../.travis.sh'),
        'text/x-shellscript',
      ),
      tuple(Io\Path::create(__DIR__.'/../../../.travis.yml'), 'text/plain'),
      tuple(Io\Path::create(__DIR__.'/../../../LICENSE'), 'text/plain'),
      tuple(Io\Path::create(__DIR__.'/../../../composer.json'), 'text/plain'),
      // Known issue.
      tuple(Io\Path::create(__FILE__), 'text/x-c++'),
    ];
  }

  public function testMimeTypeThrowsIfFileDoesntExists(): void {
    expect(() ==> {
      new Io\File(static::createPath(), false)
      |> $$->mimeType();
    })->toThrow(Io\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideResetData')>>
  public function testReset(Io\File $file, Io\Path $path): void {
    expect($file->reset($path)->path())->toBeSame($path);
  }

  public function provideResetData(): Container<(Io\File, Io\Path)> {
    return vec[
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
    ];
  }

  <<DataProvider('provideNodes')>>
  public function testResetWithDefaultArgumentWillJustClearStateWithoutChangingPath(
    Io\File $file
  ): void {
    $path = $file->path()->toString();
    expect($file->reset()->path()->toString())->toBeSame($path);
    expect($file->reset()->path()->toString())->toNotBeSame('');
  }

  <<DataProvider('provideNodes')>>
  public function testResetThrowsIfProvidedPathIsAFolder(
    Io\File $file
  ): void {
    expect(() ==> {
      $path = static::createFolder()->path();
      $file->reset($path);
    })->toThrow(
      Io\Exception\InvalidPathException::class,
      'folders are not allowed',
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testAppend(
    Io\File $file
  ): Awaitable<void> {
    await $file->append('a');
    $content = await $file->read();
    expect($content)->toBeSame('a');
    await $file->append('b');
    $content = await $file->read();
    expect($content)->toBeSame('ab');
  }

  <<DataProvider('provideNodes')>>
  public function testAppendThrowsIfFileIsNotWritable(
    Io\File $file
  ): void {
    $this->markAsSkippedIfRoot();

    expect(async () ==> {
      // read only
      await $file->chmod(0444);
      await $file->append('foo');
    })->toThrow(
      Io\Exception\WriteErrorException::class,
      'Error while appending data to file',
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testPrepend(
    Io\File $file
  ): Awaitable<void> {
    await $file->prepend('a');
    $content = await $file->read();
    expect($content)->toBeSame('a');
    await $file->prepend('b');
    $content = await $file->read();
    expect($content)->toBeSame('ba');
  }

  <<DataProvider('provideNodes')>>
  public function testPrependThrowsIfFileIsNotWritable(
    Io\File $file
  ): void {
    $this->markAsSkippedIfRoot();

    expect(async () ==> {
      // read only
      await $file->chmod(0444);
      await $file->prepend('foo');
    })->toThrow(
      Io\Exception\WriteErrorException::class,
      'Error while prepending data to file',
    );
  }

  <<DataProvider('provideNodes')>>
  public function testPrependThrowsIfFileIsNotReadable(
    Io\File $file
  ): void {
    $this->markAsSkippedIfRoot();

    expect(async () ==> {
      // execute only
      await $file->chmod(0111);
      await $file->prepend('foo');
    })->toThrow(
      Io\Exception\WriteErrorException::class,
      'Error while prepending data to file',
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testWrite(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foo');
    $content = await $file->read();
    expect($content)->toBeSame('foo');
  }

  <<DataProvider('provideNodes')>>
  public async function testWriteWithOpenOrCreateMode(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foo', Filesystem\FileWriteMode::OPEN_OR_CREATE);
    $content = await $file->read();
    expect($content)->toBeSame('foo');
    await $file->delete();
    await $file->write('bar', Filesystem\FileWriteMode::OPEN_OR_CREATE);
    $content = await $file->read();
    expect($content)->toBeSame('bar');
  }

  <<DataProvider('provideNodes')>>
  public async function testWriteWithAppendMode(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foo', Filesystem\FileWriteMode::APPEND);
    $content = await $file->read();
    expect($content)->toBeSame('foo');
    await $file->write('bar', Filesystem\FileWriteMode::APPEND);
    $content = await $file->read();
    expect($content)->toBeSame('foobar');
  }

  <<DataProvider('provideMissingNodes')>>
  public async function testWriteWithMustCreateMode(
    Io\File $file
  ): Awaitable<void> {
    expect($file->exists())->toBeFalse();
    await $file->write('foo', Filesystem\FileWriteMode::MUST_CREATE);
    expect($file->exists())->toBeTrue();
    $content = await $file->read();
    expect($content)->toBeSame('foo');

    expect(async () ==> {
      await $file->write('bar', Filesystem\FileWriteMode::MUST_CREATE);
    })->toThrow(Io\Exception\WriteErrorException::class, 'Error');
  }

  <<DataProvider('provideNodes')>>
  public async function testRead(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foobar');

    $content = await $file->read();
    expect($content)->toBeSame('foobar');

    $content = await $file->read(null);
    expect($content)->toBeSame('foobar');

    $content = await $file->read(3);
    expect($content)->toBeSame('foo');

    expect(async () ==> {
      await $file->read(-1);
    })->toThrow(
      Io\Exception\ReadErrorException::class,
      'Error while reading from file',
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testLines(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foo'."\n");
    await $file->append('bar'."\n");
    $lines = await $file->lines();
    expect($lines->count())->toBeSame(2);
    expect($lines->first())->toBeSame('foo');
    expect($lines->toString())->toBeSame("foo\nbar");
  }

  <<DataProvider('provideNodes')>>
  public async function testLinesRemovesLastEmptyLine(
    Io\File $file
  ): Awaitable<void> {
    await $file->write('foo'."\n");
    await $file->append('bar'."\n");
    await $file->append('baz'."\n");
    $lines = await $file->lines();
    expect($lines->count())->toBeSame(3);
    expect($lines->first())->toBeSame('foo');
    expect($lines->toString())->toBeSame("foo\nbar\nbaz");
  }

  <<DataProvider('provideLinkData')>>
  public async function testLink(
    Io\File $file,
    Io\Path $path,
  ): Awaitable<void> {
    $link = await $file->link($path);
    expect($path->exists())->toBeTrue();
    expect($link->path()->toString())->toBeSame($path->toString());
  }

  public function provideLinkData(): Container<(Io\File, Io\Path)> {
    return vec[
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
    ];
  }

  <<DataProvider('provideExistingNodesPair')>>
  public function testLinkThrowsIfLinkExists(
    Io\File $file,
    Io\File $target
  ): void {
    expect(async () ==> {
      await $file->link($target->path());
    })->toThrow(Io\Exception\InvalidPathException::class, 'already exists.');
  }

  <<DataProvider('provideMissingNodes')>>
  public function testLinkThrowsIfFileIsMissing(
    Io\File $file
  ): void {
    expect(async () ==> {
      await $file->link(static::createPath());
    })->toThrow(Io\Exception\MissingNodeException::class, 'doesn\'t exist');
  }

  <<DataProvider('provideSymlinkData')>>
  public async function testSymlink(
    Io\File $file,
    Io\Path $path,
  ): Awaitable<void> {
    $link = await $file->symlink($path);
    expect($link->path()->isSymlink())->toBeTrue();
    expect($link->path()->toString())->toBeSame($path->toString());
  }

  public function provideSymlinkData(): Container<(Io\File, Io\Path)> {
    return vec[
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
      tuple(static::createFile(), static::createPath()),
    ];
  }

  <<DataProvider('provideExistingNodesPair')>>
  public function testSymlinkThrowsIfLinkExists(
    Io\File $file,
    Io\File $target,
  ): void {
    expect(async () ==> {
      await $file->symlink($target->path());
    })->toThrow(Io\Exception\InvalidPathException::class, 'already exists.');
  }

  <<DataProvider('provideMissingNodes')>>
  public function testSymlinkThrowsIfFileIsMissing(
    Io\File $file
  ): void {
    expect(async () ==> {
      await $file->symlink(static::createPath());
    })->toThrow(Io\Exception\MissingNodeException::class, 'doesn\'t exist');
  }

  public function provideNodes(): Container<(Io\Node)> {
    return vec[
      tuple(static::createFile()),
      tuple(static::createFile()),
      tuple(static::createFile()),
    ];
  }

  public function provideMissingNodes(): Container<(Io\Node)> {
    return vec[
      tuple(new Io\File(static::createPath(), false)),
      tuple(new Io\File(static::createPath(), false)),
      tuple(new Io\File(static::createPath(), false)),
    ];
  }
}
