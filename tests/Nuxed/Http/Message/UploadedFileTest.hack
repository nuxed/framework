namespace Nuxed\Test\Http\Message;

use namespace Nuxed\Io;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Http\Message\Exception;
use type Nuxed\Contract\Http\Message\StreamInterface;
use type Nuxed\Contract\Http\Message\UploadedFileError;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;

class UploadedFileTest extends HackTest {
  public function testGetStreamReturnsOriginalStreamObject(): void {
    $stream = Message\stream('');
    $upload = new Message\UploadedFile($stream, 0, UploadedFileError::ERROR_OK);
    expect($upload->getStream())->toBeSame($stream);
  }

  public async function testSuccessful(): Awaitable<void> {
    $stream = Message\stream('Foo bar!');
    $upload = new Message\UploadedFile(
      $stream,
      8,
      UploadedFileError::ERROR_OK,
      'filename.txt',
      'text/plain',
    );
    $to = await Io\File::temporary('test');
    expect($upload->getSize())->toBePHPEqual(8);
    expect($upload->getClientFilename())->toBePHPEqual('filename.txt');
    expect($upload->getClientMediaType())->toBePHPEqual('text/plain');
    await $upload->moveTo($to->path()->toString());
    $content = await $stream->readAsync();
    $moved = await $to->read();
    expect($moved)->toBeSame($content);
  }

  public async function testMoveCannotBeCalledMoreThanOnce(): Awaitable<void> {
    $stream = Message\stream('Foo bar!');
    $upload = new Message\UploadedFile($stream, 0, UploadedFileError::ERROR_OK);
    $to = await Io\File::temporary('test');
    await $upload->moveTo($to->path()->toString());
    expect($to->exists())->toBeTrue();
    expect(() ==> $upload->moveTo($to->path()->toString()))
      ->toThrow(
        Exception\UploadedFileAlreadyMovedException::class,
        'Cannot retrieve stream after it has already moved',
      );
  }

  public async function testCannotRetrieveStreamAfterMove(): Awaitable<void> {
    $stream = Message\stream('Foo bar!');
    $upload = new Message\UploadedFile($stream, 0, UploadedFileError::ERROR_OK);
    $to = await Io\File::temporary('test');
    await $upload->moveTo($to->path()->toString());
    expect(() ==> {
      $upload->getStream();
    })->toThrow(
      Exception\UploadedFileAlreadyMovedException::class,
      'Cannot retrieve stream after it has already moved',
    );
  }

  public function nonOkErrorStatus(): Container<(UploadedFileError)> {
    return vec[
      tuple(UploadedFileError::ERROR_EXCEEDS_MAX_INI_SIZE),
      tuple(UploadedFileError::ERROR_EXCEEDS_MAX_FORM_SIZE),
      tuple(UploadedFileError::ERROR_INCOMPLETE),
      tuple(UploadedFileError::ERROR_NO_FILE),
      tuple(UploadedFileError::ERROR_TMP_DIR_NOT_SPECIFIED),
      tuple(UploadedFileError::ERROR_TMP_DIR_NOT_WRITEABLE),
      tuple(UploadedFileError::ERROR_CANCELED_BY_EXTENSION),
    ];
  }

  <<DataProvider('nonOkErrorStatus')>>
  public function testConstructorDoesNotRaiseExceptionForInvalidStreamWhenErrorStatusPresent(
    UploadedFileError $status,
  ): void {
    $uploadedFile = new Message\UploadedFile(Message\stream(''), 0, $status);
    expect($uploadedFile->getError())->toBeSame($status);
  }

  <<DataProvider('nonOkErrorStatus')>>
  public function testMoveToRaisesExceptionWhenErrorStatusPresent(
    UploadedFileError $status,
  ): void {
    $uploadedFile = new Message\UploadedFile(Message\stream(''), 0, $status);
    expect(async () ==> {
      $to = await Io\File::temporary('test');
      await $uploadedFile->moveTo($to->path()->toString());
    })->toThrow(
      Exception\UploadedFileErrorException::class,
      'Cannot retrieve stream due to upload error',
    );
  }

  <<DataProvider('nonOkErrorStatus')>>
  public function testGetStreamRaisesExceptionWhenErrorStatusPresent(
    UploadedFileError $status,
  ): void {
    $uploadedFile = new Message\UploadedFile(Message\stream(''), 0, $status);
    expect(() ==> {
      $stream = $uploadedFile->getStream();
    })->toThrow(
      Exception\UploadedFileErrorException::class,
      'Cannot retrieve stream due to upload error',
    );
  }
}
