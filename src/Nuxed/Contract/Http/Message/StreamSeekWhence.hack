namespace Nuxed\Contract\Http\Message;

/**
 * Specifies how the cursor position will be calculated
 * based on the seek offset. Valid values are identical to the built-in
 * Hack $whence values for `fseek()`.
 */
enum StreamSeekWhence: int {
  /**
   * Set position equal to offset bytes.
   */
  SET = \SEEK_SET;
  /**
   * Set position to current location plus offset.
   */
  CURRENT = \SEEK_CUR;
  /**
   * Set position to end-of-file plus offset.
   */
  END = \SEEK_END;
}
