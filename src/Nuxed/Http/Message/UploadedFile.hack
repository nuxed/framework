namespace Nuxed\Http\Message;

use namespace HH\Lib\Experimental\Filesystem;

class UploadedFile {
  private bool $moved = false;

  public function __construct(
    private IStream $stream,
    private ?int $size,
    private UploadedFileError $error,
    private ?string $clientFilename = null,
    private ?string $clientMediaType = null,
  ) {}

  /**
   * @return bool return true if there is no upload error
   */
  private function isOk(): bool {
    return UploadedFileError::ERROR_OK === $this->error;
  }

  /**
   * @throws Exception\IException if is moved or not ok
   */
  private function validateActive(): void {
    if (false === $this->isOk()) {
      throw new Exception\UploadedFileErrorException(
        'Cannot retrieve stream due to upload error.',
      );
    }

    if ($this->moved) {
      throw new Exception\UploadedFileAlreadyMovedException();
    }
  }

  public function getStream(): IStream {
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
      $target = Filesystem\open_write_only(
        $targetPath,
        Filesystem\FileWriteMode::OPEN_OR_CREATE,
      )
    ) {
      while (!$stream->isEndOfFile()) {
        $content = await $stream->readAsync(1048576);
        await $target->writeAsync($content);
      }
    }

    if ($stream->isSeekable()) {
      $stream->rewind();
    }

    $this->moved = true;
  }

  public function getSize(): ?int {
    return $this->size;
  }

  public function getError(): UploadedFileError {
    return $this->error;
  }

  public function getClientFilename(): ?string {
    return $this->clientFilename;
  }

  public function getClientMediaType(): ?string {
    return $this->clientMediaType;
  }
}
