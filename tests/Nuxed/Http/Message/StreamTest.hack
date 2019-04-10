namespace Nuxed\Test\Http\Message;

use type Nuxed\Http\Message\Stream;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;

class StreamTest extends HackTest {
  public async function testConstructorInitializesProperties(): Awaitable<void> {
    $handle = \fopen('php://temp', 'rb+');
    \fwrite($handle, 'data');
    $stream = new Stream($handle);
    expect($stream->isReadable())->toBeTrue();
    expect($stream->isWritable())->toBeTrue();
    expect($stream->isSeekable())->toBeTrue();
    expect($stream->getSize())->toBeSame(4);
    expect($stream->isEndOfFile())->toBeFalse();
    await $stream->closeAsync();
  }

  public async function testRead(): Awaitable<void> {
    $handle = \fopen('php://temp', 'wb+');
    \fwrite($handle, 'data');
    $stream = new Stream($handle);
    $content = await $stream->readAsync();
    expect($content)->toBeSame('');
    $stream->seek(0);
    $content = await $stream->readAsync();
    expect($content)->toBeSame('data');
    $content = await $stream->readAsync();
    expect($content)->toBeSame('');
  }

  public async function testChecksEof(): Awaitable<void> {
    $handle = \fopen('php://temp', 'wb+');
    \fwrite($handle, 'data');
    $stream = new Stream($handle);
    expect($stream->isEndOfFile())->toBeFalse();
    await $stream->readAsync(4);
    expect($stream->isEndOfFile())->toBeTrue();
    await $stream->closeAsync();
  }

  public async function testGetSize(): Awaitable<void> {
    $size = \filesize(__FILE__);
    $handle = \fopen(__FILE__, 'rb');
    $stream = new Stream($handle);
    expect($stream->getSize())->toBeSame($size);
    await $stream->closeAsync();
  }

  public async function testEnsuresSizeIsConsistent(): Awaitable<void> {
    $h = \fopen('php://temp', 'wb+');
    expect(\fwrite($h, 'foo'))->toBeSame(3);
    $stream = new Stream($h);
    expect($stream->getSize())->toBeSame(3);
    await $stream->writeAsync('test');
    await $stream->flushAsync();
    expect($stream->getSize())->toBeSame(7);
    expect($stream->getSize())->toBeSame(7);
    await $stream->closeAsync();
  }

  public async function testProvidesStreamPosition(): Awaitable<void> {
    $handle = \fopen('php://temp', 'wb+');
    $stream = new Stream($handle);
    expect($stream->tell())->toBeSame(0);
    await $stream->writeAsync('foo');
    expect($stream->tell())->toBeSame(3);
    $stream->seek(1);
    expect($stream->tell())->toBeSame(1);
    expect($stream->tell())->toBeSame(\ftell($handle));
    await $stream->closeAsync();
  }
}
