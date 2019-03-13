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
      tuple(Io\Path::create(__FILE__)),
      tuple(Io\Path::create(__DIR__.'/PathTest.hack')),
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

  public async function testGetReadHandleThrowsForUnreadableFiles(
  ): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    $file = static::createFile();
    await $file->chmod(0000);
    expect(async () ==> {
      await using $handle = $file->getReadHandle();
    })->toThrow(Io\Exception\UnreadableFileException::class);
  }

  public async function testGetWriteHandleThrowsForUnwritableFiles(
  ): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    $file = static::createFile();
    // execute only
    await $file->chmod(0111);
    expect(async () ==> {
      await using $handle = $file->getWriteHandle();
    })->toThrow(Io\Exception\UnwritableFileException::class);
  }

  public async function testGetReadHandle(): Awaitable<void> {
    $file = static::createFile();
    await $file->write('foo');
    await using ($handle = $file->getReadHandle()) {
      $content = await $handle->readAsync();
      expect($content)->toBeSame('foo');
    }
  }

  public async function testGetWriteHandle(): Awaitable<void> {
    $file = static::createFile();
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
    expect($dir->exists())->toBeTrue();
    expect($path->exists())->toBeTrue();
  }

  public async function testCreateFailsIfFileAlreadyExist(): Awaitable<void> {
    $file = static::createFile();
    $ret = await $file->create();
    expect($ret)->toBeFalse();
  }

  public async function testCopyReturnsNullIfFileDoesntExist(
  ): Awaitable<void> {
    $file = static::createFile();
    await $file->delete();
    $ret = await $file->copy(static::createPath());
    expect($ret)->toBeNull();
  }

  public async function testCopyThrowsIfTargetExistWithSkipOperation(
  ): Awaitable<void> {
    expect(async () ==> {
      $file = static::createFile();
      $target = static::createFile()->path();
      await $file->copy($target, Io\OperationType::SKIP);
    })->toThrow(Io\Exception\ExistingFileException::class);
  }

  public async function testCopyReturnsNullWhenOperationFails(
  ): Awaitable<void> {
    $file = static::createFile();
    $path = Io\Path::create('/foo/bar/baz.tmp');
    $ret = await $file->copy($path);
    expect($ret)->toBeNull();
  }

  public async function testCopySetsTargetPermissionsToSamePermissionsOfTheFile(
  ): Awaitable<void> {
    $file = static::createFile();
    await $file->chmod(0766);
    $path = static::createPath();
    $copy = await $file->copy($path);
    expect($copy)->toBeInstanceOf(Io\File::class);
    expect($copy?->permissions())->toBeSame(0766);
  }

  public async function testCopyWithPermissions(): Awaitable<void> {
    $file = static::createFile();
    $path = static::createPath();
    $copy = await $file->copy($path, Io\OperationType::SKIP, 0733);
    expect($copy?->permissions())->toBeSame(0733);
  }

  public async function testDelete(): Awaitable<void> {
    $file = static::createFile();
    $ret = await $file->delete();
    expect($ret)->toBeTrue();
  }

  public async function testDeleteReturnsFalseIfFileDoesntExists(
  ): Awaitable<void> {
    $file = new Io\File(static::createPath(), $createFile = false);
    $ret = await $file->delete();
    expect($ret)->toBeFalse();
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
      tuple(Io\Path::create(__FILE__), 'hack'),
      tuple(Io\Path::create('path/to/hhvm-4-main.hack'), 'hack'),
      tuple(Io\Path::create('path/to/hhvm-3-main.hh'), 'hh'),
      tuple(Io\Path::create('config.yml'), 'yml'),
      tuple(Io\Path::create(__DIR__.'/../../.gitignore'), 'gitignore'),
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

  public function testMd5ReturnsEmptyStringIfFileDoesntExists(): void {
    $file = new Io\File('/foo/bar', false);
    expect($file->md5())->toBeEmpty();
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

  public function testMimeTypeReturnsEmptyStringIfFileDoesntExists(): void {
    $file = new Io\File(__DIR__.'/foo.hack', false);
    expect($file->mimeType())->toBeEmpty();
  }

  <<DataProvider('provideResetData')>>
  public function testReset(Io\File $file, Io\Path $path): void {
    expect($file->reset($path)->path())->toBeSame($path);
  }

  public function provideResetData(): Container<(Io\File, Io\Path)> {
    return vec[
      tuple(static::createFile(), static::createPath()),
      tuple(Io\Node::load(__FILE__) as Io\File, static::createPath()),
      tuple(Io\Node::load(__FILE__) as Io\File, Io\Path::create(__FILE__)),
    ];
  }

  public function testResetWithDefaultArgumentWillJustClearStateWithoutChangingPath(
  ): void {
    $file = static::createFile();
    $path = $file->path()->toString();
    expect($file->reset()->path()->toString())->toBeSame($path);
    expect($file->reset()->path()->toString())->toNotBeSame('');
  }

  public function testResetThrowsIfProvidedPathIsAFolder(): void {
    expect(() ==> {
      $path = Io\Path::create(__DIR__);
      $file = static::createFile();
      $file->reset($path);
    })->toThrow(
      Io\Exception\InvalidPathException::class,
      'folders are not allowed',
    );
  }


  public async function testAppend(): Awaitable<void> {
    $file = static::createFile();
    await $file->append('a');
    $content = await $file->read();
    expect($content)->toBeSame('a');
    await $file->append('b');
    $content = await $file->read();
    expect($content)->toBeSame('ab');
  }

  public function testAppendThrowsIfFileIsNotWritable(): void {
    $this->markAsSkippedIfRoot();

    expect(async () ==> {
      $file = static::createFile();
      // read only
      await $file->chmod(0444);
      await $file->append('foo');
    })->toThrow(
      Io\Exception\WriteErrorException::class,
      'Error while appending data to file',
    );
  }

  public async function testPrepend(): Awaitable<void> {
    $file = static::createFile();
    await $file->prepend('a');
    $content = await $file->read();
    expect($content)->toBeSame('a');
    await $file->prepend('b');
    $content = await $file->read();
    expect($content)->toBeSame('ba');
  }

  public function testPrependThrowsIfFileIsNotWritable(): void {
    $this->markAsSkippedIfRoot();

    expect(async () ==> {
      $file = static::createFile();
      // read only
      await $file->chmod(0444);
      await $file->prepend('foo');
    })->toThrow(
      Io\Exception\WriteErrorException::class,
      'Error while prepending data to file',
    );
  }

  public function testPrependThrowsIfFileIsNotReadable(): void {
    $this->markAsSkippedIfRoot();

    expect(async () ==> {
      $file = static::createFile();
      // execute only
      await $file->chmod(0111);
      await $file->prepend('foo');
    })->toThrow(
      Io\Exception\WriteErrorException::class,
      'Error while prepending data to file',
    );
  }

  public async function testWrite(): Awaitable<void> {
    $file = static::createFile();
    await $file->write('foo');
    $content = await $file->read();
    expect($content)->toBeSame('foo');
  }

  public async function testWriteWithOpenOrCreateMode(): Awaitable<void> {
    $file = static::createFile();
    await $file->write('foo', Filesystem\FileWriteMode::OPEN_OR_CREATE);
    $content = await $file->read();
    expect($content)->toBeSame('foo');
    await $file->delete();
    await $file->write('bar', Filesystem\FileWriteMode::OPEN_OR_CREATE);
    $content = await $file->read();
    expect($content)->toBeSame('bar');
  }

  public async function testWriteWithAppendMode(): Awaitable<void> {
    $file = static::createFile();
    await $file->write('foo', Filesystem\FileWriteMode::APPEND);
    $content = await $file->read();
    expect($content)->toBeSame('foo');
    await $file->write('bar', Filesystem\FileWriteMode::APPEND);
    $content = await $file->read();
    expect($content)->toBeSame('foobar');
  }

  public async function testWriteWithMustCreateMode(): Awaitable<void> {
    $file = new Io\File(static::createPath(), false);
    expect($file->exists())->toBeFalse();
    await $file->write('foo', Filesystem\FileWriteMode::MUST_CREATE);
    expect($file->exists())->toBeTrue();
    $content = await $file->read();
    expect($content)->toBeSame('foo');

    expect(async () ==> {
      await $file->write('bar', Filesystem\FileWriteMode::MUST_CREATE);
    })->toThrow(Io\Exception\WriteErrorException::class, 'Error');
  }

  public async function testRead(): Awaitable<void> {
    $file = static::createFile();
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

  public async function testLines(): Awaitable<void> {
    $file = static::createFile();
    await $file->append('foo'."\n");
    await $file->append('bar'."\n");
    await $file->append('baz');
    $lines = await $file->lines();
    expect($lines->count())->toBeSame(3);
    expect($lines->first())->toBeSame('foo');
    expect($lines->toString())->toBeSame("foo\nbar\nbaz");
  }

  public async function testLinesRemovesLastEmptyLine(): Awaitable<void> {
    $file = static::createFile();
    await $file->append('foo'."\n");
    await $file->append('bar'."\n");
    await $file->append('baz'."\n");
    $lines = await $file->lines();
    expect($lines->count())->toBeSame(3);
    expect($lines->first())->toBeSame('foo');
    expect($lines->toString())->toBeSame("foo\nbar\nbaz");
  }

  <<DataProvider('provideLinkData')>>
  public function testLink(Io\File $file, Io\Path $path): void {
    $link = $file->link($path);
    expect($path->exists())->toBeTrue();
    expect($link->path()->toString())->toBeSame($path->toString());
  }

  public function provideLinkData(): Container<(Io\File, Io\Path)> {
    return vec[
      tuple(static::createFile(), static::createPath()),
      tuple(Io\Node::load(__FILE__) as Io\File, static::createPath()),
    ];
  }

  public function testLinkThrowsIfLinkExists(): void {
    expect(() ==> {
      $file = static::createFile();
      $file->link(static::createFile()->path());
    })->toThrow(Io\Exception\InvalidPathException::class, 'already exists.');
  }

  public function testLinkThrowsIfFileIsMissing(): void {
    expect(() ==> {
      $file = new Io\File(static::createPath(), false);
      $file->link(static::createPath());
    })->toThrow(Io\Exception\MissingFileException::class, 'doesn\'t exist');
  }

  <<DataProvider('provideSymlinkData')>>
  public function testSymlink(Io\File $file, Io\Path $path): void {
    $link = $file->symlink($path);
    expect($link->path()->isSymlink())->toBeTrue();
    expect($link->path()->toString())->toBeSame($path->toString());
  }

  public function provideSymlinkData(): Container<(Io\File, Io\Path)> {
    return vec[
      tuple(static::createFile(), static::createPath()),
      tuple(Io\Node::load(__FILE__) as Io\File, static::createPath()),
    ];
  }

  public function testSymlinkThrowsIfLinkExists(): void {
    expect(() ==> {
      $file = static::createFile();
      $file->symlink(static::createFile()->path());
    })->toThrow(Io\Exception\InvalidPathException::class, 'already exists.');
  }

  public function testSymlinkThrowsIfFileIsMissing(): void {
    expect(() ==> {
      $file = new Io\File(static::createPath(), false);
      $file->symlink(static::createPath());
    })->toThrow(Io\Exception\MissingFileException::class, 'doesn\'t exist');
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
      tuple(new Io\File('missing', false)),
      tuple(new Io\File(static::createPath(), false)),
      tuple(new Io\File(static::createPath(), false)),
    ];
  }
}
