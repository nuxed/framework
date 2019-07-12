namespace Nuxed\Test\Filesystem;

use namespace HH\Asio;
use namespace Nuxed\Filesystem;
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
  public async function testChmod(Filesystem\Node $node): Awaitable<void> {
    try {
      $ret = await $node->chmod(0111);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0111);

      $ret = await $node->chmod(0222);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0222);

      $ret = await $node->chmod(0333);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0333);

      $ret = await $node->chmod(0444);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0444);

      $ret = await $node->chmod(0555);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0555);

      $ret = await $node->chmod(0666);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0666);

      $ret = await $node->chmod(0777);
      expect($ret)->toBeTrue();
      expect($node->permissions())->toBeSame(0777);
    } finally {
      await $node->chmod(0777);
    }
  }

  <<DataProvider('provideNodes')>>
  public async function testAccessTime(Filesystem\Node $node): Awaitable<void> {
    $time1 = (int)microtime(true);
    expect($node->accessTime())->toBeLessThanOrEqualTo($time1);

    if ($node is Filesystem\File && getenv('TEST_LONG_RUN') !== false) {
      await Asio\usleep(10000000);
      await $node->read();
      $time2 = (int)microtime(true);
      expect($node->accessTime())->toBeGreaterThan($time1);
      expect($node->accessTime())->toBeLessThanOrEqualTo($time2);
    }
  }

  <<DataProvider('provideMissingNodes')>>
  public function testAccessTimeThrowsIfFileIsMissing(Filesystem\Node $node): void {
    expect(() ==> $node->accessTime())
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testChangeTime(Filesystem\Node $node): Awaitable<void> {
    $time1 = (int)microtime(true);
    expect($node->changeTime())->toBeLessThanOrEqualTo($time1);

    if ($node is Filesystem\File && getenv('TEST_LONG_RUN') !== false) {
      await Asio\usleep(10000000);
      // change node
      await $node->write('foo');
      $time2 = (int)microtime(true);
      expect($node->changeTime())->toBeGreaterThan($time1);
      expect($node->changeTime())->toBeLessThanOrEqualTo($time2);
    }
  }

  <<DataProvider('provideMissingNodes')>>
  public function testChangeTimeThrowsFileIsMissing(Filesystem\Node $node): void {
    expect(() ==> $node->changeTime())
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public function testBasename(Filesystem\Node $node): void {
    expect($node->basename())->toBeSame($node->path()->basename());
  }

  <<DataProvider('provideNodes')>>
  public function testName(Filesystem\Node $node): void {
    expect($node->name())->toBeSame($node->path()->name());
  }

  <<DataProvider('provideNodes')>>
  public function testDir(Filesystem\Node $node): void {
    expect($node->dir()->toString())->toBeSame(
      $node->path()->parent()->toString(),
    );
  }

  <<DataProvider('provideNodes')>>
  public async function testRename(Filesystem\Node $node): Awaitable<void> {
    $name = static::createPath()->name();
    $ret = await $node->rename($name);
    expect($ret)->toBeTrue();
    expect($node->name())->toBeSame($name);
  }


  <<DataProvider('provideMissingNodes')>>
  public async function testRenameThrowsFileIsMissing(
    Filesystem\Node $missing,
  ): Awaitable<void> {
    expect(() ==> $missing->rename('foo'))
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testRenameThrowsIfTargetExistsWithoutOverwrite(
    Filesystem\Node $node,
    Filesystem\Node $another,
  ): Awaitable<void> {
    expect(async () ==> {
      await $node->rename($another->basename(), false);
    })->toThrow(Filesystem\Exception\ExistingNodeException::class, 'already exists');
  }

  <<DataProvider('provideNodes')>>
  public async function testRenameEarlyReturn(Filesystem\Node $node): Awaitable<void> {
    $res = await $node->rename($node->basename());
    expect($res)->toBeTrue();
  }

  <<DataProvider('provideExistingNodesPair')>>
  public async function testRenameOverwrite(
    Filesystem\Node $node,
    Filesystem\Node $another,
  ): Awaitable<void> {
    $res = await $node->rename($another->basename(), true);
    expect($res)->toBeTrue();
  }

  <<DataProvider('provideNodes')>>
  public async function testWritable(Filesystem\Node $node): Awaitable<void> {
    $this->markAsSkippedIfRoot();
    // write only
    await $node->chmod(0222);
    expect($node->writable())->toBeTrue();

    // execute + read only
    await $node->chmod(0555);
    expect($node->writable())->toBeFalse();

    // reset
    await $node->chmod(0777);
  }

  <<DataProvider('provideNodes')>>
  public async function testReadable(Filesystem\Node $node): Awaitable<void> {
    $this->markAsSkippedIfRoot();
    // read only
    await $node->chmod(0444);
    expect($node->readable())->toBeTrue();

    // execute + write only
    await $node->chmod(0333);
    expect($node->readable())->toBeFalse();

    // reset
    await $node->chmod(0777);
  }

  <<DataProvider('provideNodes')>>
  public async function testExecutable(Filesystem\Node $node): Awaitable<void> {
    $this->markAsSkippedIfRoot();
    // execute only
    await $node->chmod(0111);
    expect($node->executable())->toBeTrue();

    // read + write only
    await $node->chmod(0666);
    expect($node->executable())->toBeFalse();

    // reset
    await $node->chmod(0777);
  }

  <<DataProvider('provideNodes')>>
  public async function testChown(Filesystem\Node $node): Awaitable<void> {
    $this->markAsSkippedIfNotRoot();
    $ret = await $node->chown(666, false);
    expect($ret)->toBeTrue();
    expect($node->owner())->toBeSame(666);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testChownThrowsIfNodeDoesntExist(Filesystem\Node $node): void {
    expect(() ==> $node->chown(666))
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideNodes')>>
  public async function testChgrp(Filesystem\Node $node): Awaitable<void> {
    $this->markAsSkippedIfNotRoot();
    $ret = await $node->chgrp(666, false);
    expect($ret)->toBeTrue();
    expect($node->group())->toBeSame(666);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testChgrpThrowsIfNodeDoesntExist(Filesystem\Node $node): void {
    expect(() ==> $node->chgrp(666))
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testGroupThrowsIfNodeDoesntExist(Filesystem\Node $node): void {
    expect(() ==> $node->group())
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testOwnerThrowsIfNodeDoesntExist(Filesystem\Node $node): void {
    expect(() ==> $node->owner())
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  <<DataProvider('provideMissingNodes')>>
  public function testPermissionsThrowsIfNodeDoesntExist(Filesystem\Node $node): void {
    expect(() ==> $node->permissions())
      ->toThrow(Filesystem\Exception\MissingNodeException::class);
  }

  // Data providers

  abstract public function provideNodes(): Container<(Filesystem\Node)>;
  abstract public function provideMissingNodes(): Container<(Filesystem\Node)>;

  public function provideNodesPair(): Container<(Filesystem\Node, Filesystem\Node)> {
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

  public function provideExistingNodesPair(): Container<(Filesystem\Node, Filesystem\Node)> {
    $a = vec($this->provideNodes());
    $b = Vec\reverse($this->provideNodes());
    $ret = vec[];

    foreach ($a as $i => $data) {
      $ret[] = tuple($data[0], $b[$i][0]);
    }

    return $ret;
  }

  public function provideMissingNodesPair(): Container<(Filesystem\Node, Filesystem\Node)> {
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
      static::markTestSkipped('Test cannot be executad by a superuser.');
    }
  }

  protected function markAsSkippedIfNotRoot(): void {
    if (!getenv('USER') || 'root' === getenv('USER')) {
      return;
    }
    static::markTestSkipped('Test can only be executed by a superuser.');
  }
}
