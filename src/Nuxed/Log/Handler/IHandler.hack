namespace Nuxed\Log\Handler;

use type Nuxed\Log\LogRecord;

interface IHandler {
  /**
   * Checks whether the given record will be handled by this handler.
   *
   * This is mostly done for performance reasons, to avoid calling processors for nothing.
   *
   * Handlers should still check the record levels within handle(), returning false in isHandling()
   * is no guarantee that handle() will not be called, and isHandling() might not be called
   * for a given record.
   *
   * @param LogRecord $record Partial log record containing only a level key
   *
   * @return bool
   */
  public function isHandling(LogRecord $record): bool;

  /**
   * Handles a record.
   *
   * All records may be passed to this method, and the handler should discard
   * those that it does not want to handle.
   *
   * The return value of this function controls the bubbling process of the handler stack.
   * Unless the bubbling is interrupted (by returning true), the Logger class will keep on
   * calling further handlers in the stack with a given log record.
   *
   * @param  record   $record The record to handle
   * @return bool     true means that this handler handled the record, and that bubbling is not permitted.
   *         false means the record was either not processed or that this handler allows bubbling.
   */
  public function handle(LogRecord $record): bool;

  /**
   * Closes the handler.
   *
   * Ends a log cycle and frees all resources used by the handler.
   *
   * Closing a Handler means flushing all buffers and freeing any open resources/handles.
   *
   * Implementations have to be idempotent (i.e. it should be possible to call close several times without breakage)
   * and ideally handlers should be able to reopen themselves on handle() after they have been closed.
   */
  public function close(): void;
}
