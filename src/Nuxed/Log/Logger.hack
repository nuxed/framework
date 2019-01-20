namespace Nuxed\Log;

use type Nuxed\Contract\Log\LoggerInterface;
use type Nuxed\Contract\Log\AbstractLogger;
use type Nuxed\Contract\Log\LogLevel;
use type Nuxed\Contract\Service\ResetInterface;
use type DateTime;

class Logger extends AbstractLogger implements LoggerInterface {
  public function __construct(
    public Container<Handler\HandlerInterface> $handlers,
    public Container<Processor\ProcessorInterface> $processors,
  ) {}

  <<__Override>>
  public function log(
    LogLevel $level,
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $record = shape(
      'level' => $level,
      'message' => $message,
      'context' => dict($context),
      'time' => new DateTime('now'),
      'extra' => dict[],
    );

    foreach ($this->processors as $processor) {
      $record = $processor->process($record);
    }

    foreach ($this->handlers as $handler) {
      if (!$handler->isHandling($record)) {
        continue;
      }

      if ($handler->handle($record)) {
        break;
      }
    }
  }

  /**
   * Ends a log cycle and frees all resources used by handlers.
   *
   * Closing a Handler means flushing all buffers and freeing any open resources/handles.
   * Handlers that have been closed should be able to accept log records again and re-open
   * themselves on demand, but this may not always be possible depending on implementation.
   *
   * This is useful at the end of a request and will be called automatically on every handler
   * when they get destructed.
   */
  public function close(): void {
    foreach ($this->handlers as $handler) {
      $handler->close();
    }
  }

  /**
   * Ends a log cycle and resets all handlers and processors to their initial state.
   *
   * Resetting a Handler or a Processor means flushing/cleaning all buffers, resetting internal
   * state, and getting it back to a state in which it can receive log records again.
   *
   * This is useful in case you want to avoid logs leaking between two requests or jobs when you
   * have a long running process like a worker or an application server serving multiple requests
   * in one process.
   */
  <<__Override>>
  public function reset(): void {
    foreach ($this->handlers as $handler) {
      if ($handler is ResetInterface) {
        $handler->reset();
      }
    }

    foreach ($this->processors as $processor) {
      if ($processor is ResetInterface) {
        $processor->reset();
      }
    }

    $this->close();
  }
}
