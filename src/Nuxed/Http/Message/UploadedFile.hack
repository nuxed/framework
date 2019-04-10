namespace Nuxed\Http\Message;

use namespace HH\Lib\Experimental\Filesystem;
use namespace Nuxed\Contract\Http\Message;

class UploadedFile implements Message\UploadedFileInterface {
  private bool $moved = false;

  public function __construct(
    private Message\StreamInterface $stream,
    private ?int $size,
    private Message\UploadedFileError $error,
    private ?string $clientFilename = null,
    private ?string $clientMediaType = null,
  ) {}

  /**
   * @return bool return true if there is no upload error
   */
  private function isOk(): bool {
    return Message\UploadedFileError::ERROR_OK === $this->error;
  }

  /**
   * @throws Exception\ExceptionInterface if is moved or not ok
   */
  private function validateActive(): void {
    if (false === $this->isOk()) {
      throw new Exception\UploadedFileErrorException('Cannot retrieve stream due to upload error.');
    }

    if ($this->moved) {
      throw new Exception\UploadedFileAlreadyMovedException();
    }
  }

  public function getStream(): Message\StreamInterface {
    $this->validateActive();

    return $this->stream;
  }

  public async function moveTo(string $targetPath): Awaitable<void> {
    $this->validateActive();

    if ('' === $targetPath) {
      throw new Exception\InvalidArgumentException(
        'Invalid path provided for move operation; must be a non-empty string',
      );
    }

    $stream = $this->getStream();
    if ($stream->isSeekable()) {
      $stream->rewind();
    }

    await using (
      $handle = Filesystem\open_write_only($targetPath, Filesystem\FileWriteMode::OPEN_OR_CREATE)
    ) {
      while (!$stream->isEndOfFile()) {
        $content = await $stream->readAsync(1048576);
        await $handle->writeAsync($content);
      }
    }

    $this->moved = true;
  }

  public function getSize(): ?int {
    return $this->size;
  }

  public function getError(): Message\UploadedFileError {
    return $this->error;
  }

  public function getClientFilename(): ?string {
    return $this->clientFilename;
  }

  public function getClientMediaType(): ?string {
    return $this->clientMediaType;
  }
}
