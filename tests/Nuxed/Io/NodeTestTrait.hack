namespace Nuxed\Test\Io;

use namespace HH\Asio;
use namespace Nuxed\Io;
use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;
use function microtime;
use function getenv;

trait NodeTestTrait {
  use IoTestTrait;

  require extends HackTest;

  <<DataProvider('provideNodes')>>
  public async function testChmod(Io\Node $node): Awaitable<void> {
    $permissions = $node->permissions() ?? 0755;

    $ret = await $node->chmod(0111, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0111);

    $ret = await $node->chmod(0222, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0222);

    $ret = await $node->chmod(0333, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0333);

    $ret = await $node->chmod(0444, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0444);

    $ret = await $node->chmod(0555, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0555);

    $ret = await $node->chmod(0666, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0666);

    $ret = await $node->chmod(0777, true);
    expect($ret)->toBeTrue();
    expect($node->permissions())->toBeSame(0777);

    await $node->chmod($permissions, true);
  }

  <<DataProvider('provideNodes')>>
  public async function testAccessTime(Io\Node $node): Awaitable<void> {
    $time1 = (int)microtime(true);
    expect($node->accessTime())->toBeLessThanOrEqualTo($time1);

    if ($node is Io\File && getenv('TEST_LONG_RUN') !== false) {
      await Asio\usleep(10000000);
      await $node->read();
      $time2 = (int)microtime(true);
      expect($node->accessTime())->toBeGreaterThan($time1);
      expect($node->accessTime())->toBeLessThanOrEqualTo($time2);
    }
  }

  <<DataProvider('provideMissingNodes')>>
  public function testAccessTimeReturnsZeroIfFileIsMissing(
    Io\Node $node,
  ): void {
    expect($node->accessTime())->toBeSame(0);
  }

  <<DataProvider('provideNodes')>>
  public async function testChangeTime(Io\Node $node): Awaitable<void> {
    $time1 = (int)microtime(true);
    expect($node->changeTime())->toBeLessThanOrEqualTo($time1);

    if ($node is Io\File && getenv('TEST_LONG_RUN') !== false) {
      await Asio\usleep(10000000);
      // change node
      await $node->write('foo');
      $time2 = (int)microtime(true);
      expect($node->changeTime())->toBeGreaterThan($time1);
      expect($node->changeTime())->toBeLessThanOrEqualTo($time2);
    }
  }

  <<DataProvider('provideMissingNodes')>>
  public function testChangeTimeReturnsZeroIfFileIsMissing(
    Io\Node $node,
  ): void {
    expect($node->changeTime())->toBeSame(0);
  }

  <<DataProvider('provideNodes')>>
  public function testBasename(Io\Node $node): void {
    expect($node->basename())->toBeSame($node->path()->basename());
  }

  <<DataProvider('provideNodes')>>
  public function testName(Io\Node $node): void {
    expect($node->name())->toBeSame($node->path()->name());
  }

  <<DataProvider('provideNodes')>>
  public function testDir(Io\Node $node): void {
    expect($node->dir()->toString())->toBeSame(
      $node->path()->parent()->toString(),
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testRename(Io\Node $node): Awaitable<void> {
    $name = static::createPath()->name();
    $ret = await $node->rename($name);
    expect($ret)->toBeTrue();
    expect($node->name())->toBeSame($name);
  }


  <<DataProvider('provideMissingNodes')>>
  public async function testRenameReturnsFlaseIfFileIsMissing(
    Io\Node $missing,
  ): Awaitable<void> {
    $res = await $missing->rename('foo');
    expect($res)->toBeFalse();
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testRenameThrowsIfTargetExistsWithoutOverwrite(
    Io\Node $node,
    Io\Node $another,
  ): Awaitable<void> {
    expect(async () ==> {
      await $node->rename($another->basename(), false);
    })->toThrow(Io\Exception\ExistingFileException::class, 'already exists');
  }

  <<DataProvider('provideNodes')>>
  public async function testRenameEarlyReturn(Io\Node $node): Awaitable<void> {
    $res = await $node->rename($node->basename());
    expect($res)->toBeTrue();
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testRenameOverwrite(
    Io\Node $node,
    Io\Node $another,
  ): Awaitable<void> {
    $res = await $node->rename($another->basename(), true);
    expect($res)->toBeTrue();
  }

  <<DataProvider('provideNodes')>>
  public async function testWritable(Io\Node $node): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    $mode = $node->permissions() ?? 0755;

    // write only
    await $node->chmod(0222);
    expect($node->writable())->toBeTrue();

    // execute + read only
    await $node->chmod(0555);
    expect($node->writable())->toBeFalse();

    // reset
    await $node->chmod($mode, true);
  }

  <<DataProvider('provideNodes')>>
  public async function testReadable(Io\Node $node): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    $mode = $node->permissions() ?? 0755;

    // read only
    await $node->chmod(0444);
    expect($node->readable())->toBeTrue();

    // execute + write only
    await $node->chmod(0333);
    expect($node->readable())->toBeFalse();

    // reset
    await $node->chmod($mode, true);
  }

  <<DataProvider('provideNodes')>>
  public async function testExecutable(Io\Node $node): Awaitable<void> {
    $this->markAsSkippedIfRoot();

    $mode = $node->permissions() ?? 0755;

    // execute only
    await $node->chmod(0111);
    expect($node->executable())->toBeTrue();

    // read + write only
    await $node->chmod(0666);
    expect($node->executable())->toBeFalse();

    // reset
    await $node->chmod($mode, true);
  }

  // Data providers

  abstract public function provideNodes(): Container<(Io\Node)>;
  abstract public function provideMissingNodes(): Container<(Io\Node)>;

  public function provideNodesPair(): Container<(Io\Node, Io\Node)> {
    $nodes = vec($this->provideNodes());
    $missing = vec($this->provideMissingNodes());
    if (C\count($missing) > C\count($nodes)) {
      $missing = Vec\take($missing, C\count($nodes));
    } else {
      $nodes = Vec\take($nodes, C\count($missing));
    }

    $ret = vec[];
    foreach ($nodes as $i => $data) {
      $ret[] = tuple($data[0], $missing[$i][0]);
    }

    return $ret;
  }

  public function provideExistingNodesPair(): Container<(Io\Node, Io\Node)> {
    $a = vec($this->provideNodes());
    $b = Vec\reverse($this->provideNodes());
    $ret = vec[];

    foreach ($a as $i => $data) {
      $ret[] = tuple($data[0], $b[$i][0]);
    }

    return $ret;
  }

  public function provideMissingNodesPair(): Container<(Io\Node, Io\Node)> {
    $a = vec($this->provideMissingNodes());
    $b = Vec\reverse($this->provideMissingNodes());

    $ret = vec[];
    foreach ($a as $i => $data) {
      $ret[] = tuple($data[0], $b[$i][0]);
    }

    return $ret;
  }

  protected function markAsSkippedIfRoot(): void {
    if (!getenv('USER') || 'root' === getenv('USER')) {
      static::markTestSkipped('Skipped test for superuser.');
    }
  }
}
