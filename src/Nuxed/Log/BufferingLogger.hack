namespace Nuxed\Log;

use namespace Nuxed\Log;

/**
 * A buffering logger that stacks logs for later.
 */
class BufferingLogger extends Log\AbstractLogger {
  private vec<shape(
    'level' => Log\LogLevel,
    'message' => string,
    'context' => KeyedContainer<string, mixed>,
    ...
  )> $logs = vec[];

  <<__Override>>
  public function log(
    Log\LogLevel $level,
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->logs[] = shape(
      'level' => $level,
      'message' => $message,
      'context' => $context,
    );
  }

  public function cleanLogs(
  ): vec<shape(
    'level' => Log\LogLevel,
    'message' => string,
    'context' => KeyedContainer<string, mixed>,
    ...
  )> {
    $logs = $this->logs;
    $this->reset();
    return $logs;
  }

  <<__Override>>
  public function reset(): void {
    $this->logs = vec[];
  }
}
