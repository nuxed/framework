<?hh // strict

namespace Nuxed\Test\Http\Message;

use type Nuxed\Http\Message\Stream;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;
use function fopen;
use function fwrite;
use function filesize;
use function ftell;

class StreamTest extends HackTest {
  public function testConstructorInitializesProperties(): void {
    $handle = fopen('php://temp', 'rb+');
    fwrite($handle, 'data');
    $stream = new Stream($handle);
    expect($stream->isReadable())->toBeTrue();
    expect($stream->isWritable())->toBeTrue();
    expect($stream->isSeekable())->toBeTrue();
    expect($stream->getMetadata('uri'))->toBeSame('php://temp');
    expect($stream->getSize())->toBeSame(4);
    expect($stream->eof())->toBeFalse();
    $stream->close();
  }

  public function testConvertsToString(): void {
    $handle = fopen('php://temp', 'wb+');
    fwrite($handle, 'data');
    $stream = new Stream($handle);
    expect((string)$stream)->toBeSame('data');
    expect((string)$stream)->toBeSame('data');
    $stream->close();
  }

  public function testGetsContents(): void {
    $handle = fopen('php://temp', 'wb+');
    fwrite($handle, 'data');
    $stream = new Stream($handle);
    expect($stream->getContents())->toBeSame('');
    $stream->seek(0);
    expect($stream->getContents())->toBeSame('data');
    expect($stream->getContents())->toBeSame('');
  }

  public function testChecksEof(): void {
    $handle = fopen('php://temp', 'wb+');
    fwrite($handle, 'data');
    $stream = new Stream($handle);
    expect($stream->eof())->toBeFalse();
    $stream->read(4);
    expect($stream->eof())->toBeTrue();
    $stream->close();
  }

  public function testGetSize(): void {
    $size = filesize(__FILE__);
    $handle = fopen(__FILE__, 'rb');
    $stream = new Stream($handle);
    expect($stream->getSize())->toBeSame($size);
    // Load from cache
    expect($stream->getSize())->toBeSame($size);
    $stream->close();
  }

  public function testEnsuresSizeIsConsistent(): void {
    $h = fopen('php://temp', 'wb+');
    expect(fwrite($h, 'foo'))->toBeSame(3);
    $stream = new Stream($h);
    expect($stream->getSize())->toBeSame(3);
    expect($stream->write('test'))->toBeSame(4);
    expect($stream->getSize())->toBeSame(7);
    expect($stream->getSize())->toBeSame(7);
    $stream->close();
  }

  public function testProvidesStreamPosition(): void {
    $handle = fopen('php://temp', 'wb+');
    $stream = new Stream($handle);
    expect($stream->tell())->toBeSame(0);
    $stream->write('foo');
    expect($stream->tell())->toBeSame(3);
    $stream->seek(1);
    expect($stream->tell())->toBeSame(1);
    expect($stream->tell())->toBeSame(ftell($handle));
    $stream->close();
  }

  public function testCanDetachStream(): void {
    $r = fopen('php://temp', 'wb+');
    $stream = new Stream($r);
    $stream->write('foo');
    expect($stream->isReadable())->toBeTrue();
    expect($stream->detach())->toBeSame($r);
    $stream->detach();

    expect($stream->isReadable())->toBeFalse();
    expect($stream->isWritable())->toBeFalse();
    expect($stream->isSeekable())->toBeFalse();
    expect((string)$stream)->toBeSame('');
    $stream->close();
  }

  public function testCloseClearProperties(): void {
    $handle = fopen('php://temp', 'rb+');
    $stream = new Stream($handle);
    $stream->close();
    expect($stream->isSeekable())->toBeFalse();
    expect($stream->isReadable())->toBeFalse();
    expect($stream->isWritable())->toBeFalse();
    expect($stream->getSize())->toBeNull();
    expect($stream->getMetadata())->toBeEmpty();
  }
}
