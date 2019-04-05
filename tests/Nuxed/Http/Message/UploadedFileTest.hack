namespace Nuxed\Test\Http\Message;

use namespace Nuxed\Http\Message\Exception;
use type Nuxed\Contract\Http\Message\StreamInterface;
use type Nuxed\Contract\Http\Message\UploadedFileError;
use type Nuxed\Http\Message\MessageFactory;
use type Nuxed\Http\Message\Stream;
use type Nuxed\Http\Message\UploadedFile;
use type Facebook\HackTest\HackTest;
use type Facebook\HackTest\DataProvider;
use function Facebook\FBExpect\expect;
use function is_scalar;
use function file_exists;
use function unlink;
use function fopen;
use function tempnam;
use function sys_get_temp_dir;
use function uniqid;
use function file_get_contents;

class UploadedFileTest extends HackTest {
  protected vec<string> $cleanup = vec[];

  <<__Override>>
  public async function beforeEachTestAsync(): Awaitable<void> {
    $this->cleanup = vec[];
  }

  <<__Override>>
  public async function afterEachTestAsync(): Awaitable<void> {
    foreach ($this->cleanup as $file) {
      if (file_exists($file)) {
        unlink($file);
      }
    }
  }

  public function testGetStreamReturnsOriginalStreamObject(): void {
    $stream = $this->createStream('');
    $upload = new UploadedFile($stream, 0, UploadedFileError::ERROR_OK);
    expect($upload->getStream())->toBeSame($stream);
  }

  public function testGetStreamReturnsWrappedPhpStream(): void {
    $handle = fopen('php://temp', 'wb+');
    $upload =
      new UploadedFile(new Stream($handle), 0, UploadedFileError::ERROR_OK);
    $uploadHandle = $upload->getStream()->detach();
    expect($uploadHandle)->toBeSame($handle);
    (new Stream($handle))->close();
  }

  public function testSuccessful(): void {
    $stream = $this->createStream('Foo bar!');
    $upload = new UploadedFile(
      $stream,
      $stream->getSize(),
      UploadedFileError::ERROR_OK,
      'filename.txt',
      'text/plain',
    );
    expect($upload->getSize())->toBePHPEqual($stream->getSize());
    expect($upload->getClientFilename())->toBePHPEqual('filename.txt');
    expect($upload->getClientMediaType())->toBePHPEqual('text/plain');
    $this->cleanup[] = $to = tempnam(sys_get_temp_dir(), 'successful');
    $upload->moveTo($to);
    expect(file_get_contents($to))->toBePHPEqual($stream->toString());
  }

  public function testMoveCannotBeCalledMoreThanOnce(): void {
    $stream = $this->createStream('Foo bar!');
    $upload = new UploadedFile($stream, 0, UploadedFileError::ERROR_OK);
    $this->cleanup[] = $to = tempnam(sys_get_temp_dir(), 'diac');
    $upload->moveTo($to);
    expect(file_exists($to))->toBeTrue();
    expect(() ==> {
      $upload->moveTo($to);
    })->toThrow(
      Exception\UploadedFileAlreadyMovedException::class,
      'Cannot retrieve stream after it has already moved',
    );
  }

  public function testCannotRetrieveStreamAfterMove(): void {
    $stream = $this->createStream('Foo bar!');
    $upload = new UploadedFile($stream, 0, UploadedFileError::ERROR_OK);
    $this->cleanup[] = $to = tempnam(sys_get_temp_dir(), 'diac');
    $upload->moveTo($to);
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
    $uploadedFile = new UploadedFile($this->createStream(), 0, $status);
    expect($uploadedFile->getError())->toBeSame($status);
  }

  <<DataProvider('nonOkErrorStatus')>>
  public function testMoveToRaisesExceptionWhenErrorStatusPresent(
    UploadedFileError $status,
  ): void {
    $uploadedFile = new UploadedFile($this->createStream(), 0, $status);
    expect(() ==> {
      $uploadedFile->moveTo(__DIR__.'/'.uniqid());
    })->toThrow(
      Exception\UploadedFileErrorException::class,
      'Cannot retrieve stream due to upload error',
    );
  }

  <<DataProvider('nonOkErrorStatus')>>
  public function testGetStreamRaisesExceptionWhenErrorStatusPresent(
    UploadedFileError $status,
  ): void {
    $uploadedFile = new UploadedFile($this->createStream(), 0, $status);
    expect(() ==> {
      $stream = $uploadedFile->getStream();
    })->toThrow(
      Exception\UploadedFileErrorException::class,
      'Cannot retrieve stream due to upload error',
    );
  }

  private function createStream(string $data = ''): StreamInterface {
    static $factory;
    if (null === $factory) {
      $factory = new MessageFactory();
    }
    return $factory->createStream($data);
  }
}
