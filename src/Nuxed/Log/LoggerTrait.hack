namespace Nuxed\Log;

/**
 * This is a simple Logger trait that classes unable to extend AbstractLogger
 * (because they extend another class, etc) can include.
 *
 * It simply delegates all log-level-specific methods to the `log` method to
 * reduce boilerplate code that a simple Logger that does the same thing with
 * messages regardless of the error level has to implement.
 */
trait LoggerTrait {
  require implements ILogger;

  /**
   * System is unusable.
   */
  public function emergency(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::EMERGENCY, $message, $context);
  }

  /**
   * Action must be taken immediately.
   *
   * Example: Entire website down, database unavailable, etc. This should
   * trigger the SMS alerts and wake you up.
   */
  public function alert(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::ALERT, $message, $context);
  }

  /**
   * Critical conditions.
   *
   * Example: Application component unavailable, unexpected exception.
   */
  public function critical(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::CRITICAL, $message, $context);
  }

  /**
   * Runtime errors that do not require immediate action but should typically
   * be logged and monitored.
   */
  public function error(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::ERROR, $message, $context);
  }

  /**
   * Exceptional occurrences that are not errors.
   *
   * Example: Use of deprecated APIs, poor use of an API, undesirable things
   * that are not necessarily wrong.
   */
  public function warning(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::WARNING, $message, $context);
  }

  /**
   * Normal but significant events.
   */
  public function notice(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::NOTICE, $message, $context);
  }

  /**
   * Interesting events.
   *
   * Example: User logs in, SQL logs.
   */
  public function info(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::INFO, $message, $context);
  }

  /**
   * Detailed debug information.
   */
  public function debug(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void {
    $this->log(LogLevel::DEBUG, $message, $context);
  }
}
