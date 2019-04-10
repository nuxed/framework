namespace Nuxed\Contract\Http\Message;

/**
 * Value object representing a file uploaded through an HTTP request.
 *
 * Instances of this interface are considered immutable; all methods that
 * might change state MUST be implemented such that they retain the internal
 * state of the current instance and return an instance that contains the
 * changed state.
 */
interface UploadedFileInterface {
  /**
   * Retrieve a stream representing the uploaded file.
   *
   * This method MUST return a StreamInterface instance, representing the
   * uploaded file. The purpose of this method is to allow utilizing native Hack
   * stream functionality to manipulate the file upload, such as
   * stream_copy_to_stream() (though the result will need to be decorated in a
   * native Hack stream wrapper to work with such functions).
   *
   * If the moveTo() method has been called previously, this method MUST raise
   * an exception.
   *
   * @return StreamInterface Stream representation of the uploaded file.
   * @throws \RuntimeException in cases when no stream is available or can be
   *     created.
   */
  public function getStream(): StreamInterface;

  /**
   * Move the uploaded file to a new location.
   *
   * Use this method as an alternative to move_uploaded_file(). This method is
   * guaranteed to work in both SAPI and non-SAPI environments.
   * Implementations must determine which environment they are in, and use the
   * appropriate method (move_uploaded_file(), rename(), or a stream
   * operation) to perform the operation.
   *
   * $targetPath may be an absolute path, or a relative path. If it is a
   * relative path, resolution should be the same as used by Hack's rename()
   * function.
   *
   * The original file or stream MUST be removed on completion.
   *
   * If this method is called more than once, any subsequent calls MUST raise
   * an exception.
   *
   * When used in an SAPI environment where $_FILES is populated, when writing
   * files via moveTo(), is_uploaded_file() and move_uploaded_file() SHOULD be
   * used to ensure permissions and upload status are verified correctly.
   *
   * If you wish to move to a stream, use getStream(), as SAPI operations
   * cannot guarantee writing to stream destinations.
   *
   * @param string $targetPath Path to which to move the uploaded file.
   * @throws \InvalidArgumentException if the $targetPath specified is invalid.
   * @throws \RuntimeException on any error during the move operation, or on
   *     the second or subsequent call to the method.
   */
  public function moveTo(string $targetPath): Awaitable<void>;

  /**
   * Retrieve the file size.
   *
   * Implementations SHOULD return the value stored in the "size" key of
   * the file in the $_FILES array if available, as Hack calculates this based
   * on the actual size transmitted.
   *
   * @return int|null The file size in bytes or null if unknown.
   */
  public function getSize(): ?int;

  /**
   * Retrieve the error associated with the uploaded file.
   *
   * If the file was uploaded successfully, this method MUST return UploadedFileError::ERROR_OK.
   */
  public function getError(): UploadedFileError;

  /**
   * Retrieve the filename sent by the client.
   *
   * Do not trust the value returned by this method. A client could send
   * a malicious filename with the intention to corrupt or hack your
   * application.
   *
   * Implementations SHOULD return the value stored in the "name" key of
   * the file in the $_FILES array.
   *
   * @return string|null The filename sent by the client or null if none
   *     was provided.
   */
  public function getClientFilename(): ?string;

  /**
   * Retrieve the media type sent by the client.
   *
   * Do not trust the value returned by this method. A client could send
   * a malicious media type with the intention to corrupt or hack your
   * application.
   *
   * Implementations SHOULD return the value stored in the "type" key of
   * the file in the $_FILES array.
   *
   * @return string|null The media type sent by the client or null if none
   *     was provided.
   */
  public function getClientMediaType(): ?string;
}
