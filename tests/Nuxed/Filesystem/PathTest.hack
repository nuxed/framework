namespace Nuxed\Test\Filesystem;

use namespace Nuxed\Filesystem;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;
use function realpath;
use function getcwd;
use const __DIR__;
use const __FILE__;

class PathTest extends HackTest {
  use IoTestTrait;

  public function testCreate(): void {
    expect(Filesystem\Path::create('/foo/bar')->toString())->toBeSame(
      '/foo/bar',
    );
    $path = Filesystem\Path::create('/foo/bar');
    expect(Filesystem\Path::create($path))->toBeSame($path);
  }

  <<DataProvider('provideToStringAndMagicToStringData')>>
  public function testToStringAndMagicToString(
    string $path,
    string $realpath,
  ): void {
    $path = Filesystem\Path::create($path);
    expect($path->toString())->toBeSame($realpath);
    expect((string)$path)->toBeSame($realpath);
  }

  public function provideToStringAndMagicToStringData(
  ): Container<(string, string)> {
    return vec[
      tuple('/foo/bar', '/foo/bar'),
      tuple(__FILE__, __FILE__),
      tuple(__DIR__, __DIR__),
      tuple(__DIR__.'/../../', __DIR__.'/../../'),
    ];
  }

  <<DataProvider('provideExtensionData')>>
  public function testExtension(string $path, string $extension): void {
    expect(Filesystem\Path::create($path)->extension())->toBeSame($extension);
  }

  public function provideExtensionData(): Container<(string, string)> {
    return vec[
      tuple(__FILE__, 'hack'),
      tuple('image.jpeg', 'jpeg'),
      tuple('evil.cat.gif', 'gif'),
      tuple('.good.doggy.gif', 'gif'),
      tuple('composer.json', 'json'),
      tuple('composer.lock', 'lock'),
      tuple('.travis.yml', 'yml'),
    ];
  }

  <<DataProvider('provideIsAbsoluteData')>>
  public function testIsAbsolute(string $path, bool $isAbsolute): void {
    expect(Filesystem\Path::create($path)->isAbsolute())->toBeSame($isAbsolute);
  }

  public function provideIsAbsoluteData(): Container<(string, bool)> {
    return vec[
      tuple('/foo/bar', true),
      tuple('/foo/bar/', true),
      tuple('/foo', true),
      tuple('baz/', false),
      tuple('baz', false),
      tuple('baz/foo', false),
      tuple('baz/foo/', false),
      tuple('./baz/foo/', false),
      tuple('../baz/foo/', false),
    ];
  }

  <<DataProvider('provideIsRelativeData')>>
  public function testIsRelative(string $path, bool $expected): void {
    expect(Filesystem\Path::create($path)->isRelative())->toBeSame($expected);
  }

  public function provideIsRelativeData(): Container<(string, bool)> {
    return vec[
      tuple('/foo/bar', false),
      tuple('/foo/bar/', false),
      tuple('/foo', false),
      tuple('baz/', true),
      tuple('baz', true),
      tuple('baz/foo', true),
      tuple('baz/foo/', true),
      tuple('./baz/foo/', true),
      tuple('../baz/foo/', true),
    ];
  }

  <<DataProvider('provideJoinData')>>
  public function testJoin(
    Container<string> $parts,
    bool $above,
    string $expected,
  ): void {
    expect(Filesystem\Path::join($parts, $above)->toString())->toBeSame(
      $expected,
    );
  }

  public function provideJoinData(
  ): Container<(Container<string>, bool, string)> {
    return vec[
      tuple(vec['foo', 'bar'], true, 'foo/bar'),
      tuple(vec['foo/', '/bar/'], true, 'foo/bar'),
      tuple(vec['foo', '/bar/', '..', '//baz'], true, 'foo/baz'),
      tuple(
        vec['foo', '.', 'bar\\baz', '..', 'foo', '.', 'a/b/c', 'd/../e'],
        false,
        'foo/bar/foo/a/b/c/e',
      ),
      tuple(
        vec['foo', '.', 'bar/baz', '..', 'foo', '.', 'a/b\\c', 'd/..\\e'],
        false,
        'foo/bar/foo/a/b/c/e',
      ),
      tuple(vec['foo/', '..', '/bar', '.', '..', '..', '//baz'], false, 'baz'),
    ];
  }

  <<DataProvider('provideNormalizeData')>>
  public function testNormalize(string $path, ?string $expected): void {
    expect(Filesystem\Path::normalize($path))->toBeSame($expected);
  }

  public function provideNormalizeData(): Container<(string, ?string)> {
    return vec[
      tuple('', getcwd()),
      tuple('./././', getcwd()),
      tuple('/foo/bar', null),
      tuple('/baz', null),
      tuple(__DIR__.'/foo/bar', null),
      tuple(__DIR__, __DIR__),
      tuple(__DIR__.'/../', realpath(__DIR__.'/../')),
      tuple(__FILE__, __FILE__),
    ];
  }

  <<DataProvider('provideStandardData')>>
  public function testStandard(
    string $path,
    bool $endSlash,
    string $expected,
  ): void {
    expect(Filesystem\Path::standard($path, $endSlash))->toBeSame($expected);
  }

  public function provideStandardData(): Container<(string, bool, string)> {
    return vec[
      tuple('/foo\\bar/baz', false, '/foo/bar/baz'),
      tuple('/foo\\bar/baz', true, '/foo/bar/baz/'),
      tuple('foo\\bar/baz\\example.hack', false, 'foo/bar/baz/example.hack'),
      tuple('foo\\bar\\baz\\', false, 'foo/bar/baz/'),
      tuple('foo\\bar\\baz\\', true, 'foo/bar/baz/'),
      tuple('foo\\bar\\baz', false, 'foo/bar/baz'),
      tuple('foo\\bar\\baz', true, 'foo/bar/baz/'),
    ];
  }

  <<DataProvider('provideRelativeToData')>>
  public function testRelativeTo(
    string $path,
    string $to,
    string $expected,
  ): void {
    expect(
      Filesystem\Path::create($path)->relativeTo(Filesystem\Path::create($to))
        ->toString(),
    )
      ->toBeSame($expected);
  }

  public function provideRelativeToData(): Container<(string, string, string)> {
    return vec[
      tuple('/foo/bar/a/b/c/', '/foo/d/e/f/', '../../../../d/e/f/'),
      tuple('/foo/bar', '/foo/baz', '../baz/'),
      tuple('/foo/bar/baz', '/foo/bar', '../'),
      tuple('/foo/bar/', '/foo/bar/baz', './baz/'),
    ];
  }

  public function testRelativeToThrowsForAbsolutePath(): void {
    // absolute + absolute
    expect(
      () ==> Filesystem\Path::create('foo/bar')->relativeTo(
        Filesystem\Path::create('foo/bar/baz'),
      ),
    )
      ->toThrow(
        Filesystem\Exception\InvalidPathException::class,
        'Cannot determine relative path without two absolute paths.',
      );

    // relative + absolute
    expect(
      () ==> Filesystem\Path::create('/foo/bar')->relativeTo(
        Filesystem\Path::create('foo/bar/baz'),
      ),
    )
      ->toThrow(
        Filesystem\Exception\InvalidPathException::class,
        'Cannot determine relative path without two absolute paths.',
      );

    // absolute + relative
    expect(
      () ==> Filesystem\Path::create('foo/bar')->relativeTo(
        Filesystem\Path::create('/foo/bar/baz'),
      ),
    )
      ->toThrow(
        Filesystem\Exception\InvalidPathException::class,
        'Cannot determine relative path without two absolute paths.',
      );
  }

  <<DataProvider('provideIsDirectoryData')>>
  public function testIsDirectory(string $path, bool $expected): void {
    expect(Filesystem\Path::create($path)->isFolder())->toBeSame($expected);
  }

  public function provideIsDirectoryData(): Container<(string, bool)> {
    return vec[
      tuple('.', true),
      tuple(__DIR__, true),
      tuple(__DIR__.'/foo/bar', false),
      tuple(getcwd(), true),
      tuple(__DIR__.'/../Util/JsonTest.hack', false),
      tuple(__DIR__.'/../../../composer.json', false),
    ];
  }

  <<DataProvider('provideIsFileData')>>
  public function testIsFile(string $path, bool $expected): void {
    expect(Filesystem\Path::create($path)->isFile())->toBeSame($expected);
  }

  public function provideIsFileData(): Container<(string, bool)> {
    return vec[
      tuple('.', false),
      tuple(__DIR__, false),
      tuple(getcwd(), false),
      tuple(__DIR__.'/foo/bar', false),
      tuple(__FILE__, true),
      tuple(__DIR__.'/../Util/JsonTest.hack', true),
      tuple(__DIR__.'/../../../composer.json', true),
    ];
  }

  <<DataProvider('provideIsSymlinkData')>>
  public function testIsSymlink(string $path, bool $expected): void {
    expect(Filesystem\Path::create($path)->isSymlink())->toBeSame($expected);
  }

  public function provideIsSymlinkData(): Container<(string, bool)> {
    return vec[
      tuple(__FILE__, false),
      tuple(__DIR__, false),
      tuple(__DIR__.'/foo.hack', false),
      tuple('foo.hack', false),
      tuple('foo/bar.hack', false),
      tuple('/foo/bar/baz.hack', false),
      tuple(static::createSymlink()->path()->toString(), true),
      tuple(static::createSymlink()->path()->toString(), true),
      tuple(static::createSymlink()->path()->toString(), true),
      tuple(static::createSymlink()->path()->toString(), true),
      tuple(static::createSymlink()->path()->toString(), true),
    ];
  }

  <<DataProvider('provideExistsData')>>
  public function testExists(string $path, bool $expected): void {
    expect(Filesystem\Path::create($path)->exists())->toBeSame($expected);
  }

  public function provideExistsData(): Container<(string, bool)> {
    return vec[
      tuple('./foo.bar.hack', false),
      tuple(__DIR__.'/foo.hack', false),
      tuple('foo/bar/baz', false),
      tuple('/foo/bar/', false),
      tuple('/foo/bar/baz/', false),
      tuple('./foo', false),
      tuple(__DIR__, true),
      tuple(__FILE__, true),
      tuple(__DIR__.'/../Util', true),
    ];
  }

  <<DataProvider('provideParentData')>>
  public function testParent(string $path, string $expected): void {
    expect(Filesystem\Path::create($path)->parent()->toString())->toBeSame(
      $expected,
    );
  }

  public function provideParentData(): Container<(string, string)> {
    return vec[
      tuple('foo/bar/baz.gif', 'foo/bar/'),
      tuple('foo', './'),
      tuple('foo/bar/baz/', 'foo/bar/'),
      tuple('./', './'),
    ];
  }

  <<DataProvider('provideBasenameData')>>
  public function testBasename(string $path, string $expected): void {
    expect(Filesystem\Path::create($path)->basename())->toBeSame($expected);
  }

  public function provideBasenameData(): Container<(string, string)> {
    return vec[
      tuple('foo/bar/baz.gif', 'baz.gif'),
      tuple('/foo/bar/baz.gif', 'baz.gif'),
      tuple('foo/bar/baz', 'baz'),
      tuple('/foo/bar/baz', 'baz'),
      tuple('foo/bar/baz/', 'baz'),
      tuple('/foo/bar/baz/', 'baz'),
      tuple('./', '.'),
    ];
  }

  <<DataProvider('provideNameData')>>
  public function testName(string $path, string $expected): void {
    expect(Filesystem\Path::create($path)->name())->toBeSame($expected);
  }

  public function provideNameData(): Container<(string, string)> {
    return vec[
      tuple('foo/bar/baz.gif', 'baz'),
      tuple('/foo/bar/baz.gif', 'baz'),
      tuple('foo/bar/baz', 'baz'),
      tuple('/foo/bar/baz', 'baz'),
      tuple('foo/bar/baz/', 'baz'),
      tuple('/foo/bar/baz/', 'baz'),
      tuple('./', ''),
    ];
  }

  <<DataProvider('providePartsData')>>
  public function testParts(string $path, Container<string> $expected): void {
    expect(vec(Filesystem\Path::create($path)->parts()))->toBeSame(
      vec($expected),
    );
  }

  public function providePartsData(): Container<(string, Container<string>)> {
    return vec[
      tuple('/foo/bar/baz', vec['foo', 'bar', 'baz']),
      tuple('//foo/bar\\baz/', vec['foo', 'bar', 'baz']),
      tuple('foo/bar/baz', vec['foo', 'bar', 'baz']),
      tuple('foo/bar.hack/baz.hack', vec['foo', 'bar.hack', 'baz.hack']),
      tuple('baz.hack', vec['baz.hack']),
      tuple('foo', vec['foo']),
    ];
  }

  <<DataProvider('provideCompareData')>>
  public function testCompare(
    string $path,
    string $other,
    int $expected,
  ): void {
    $path = Filesystem\Path::create($path);
    expect($path->compare($other))->toBeSame($expected);
  }

  public function provideCompareData(): Container<(string, string, int)> {
    return vec[
      tuple('', '', 0),
      // last `/` should be removed
      tuple('/foo', '/foo/', 0),
      // same directory path
      tuple(__DIR__, __DIR__.'/../Filesystem/', 0),
      tuple('/foo\\bar', '/foo/bar/', 0),
      tuple(__DIR__, __DIR__.'/..', 11),
      tuple(__DIR__.'/..', __DIR__, -11),
    ];
  }
}
