namespace Nuxed\Contract\Log;

use type Nuxed\Contract\Service\ResetInterface;

/**
 * Describes a logger instance.
 *
 * The message MUST be a string or object implementing __toString().
 *
 * The message MAY contain placeholders in the form: {foo} where foo
 * will be replaced by the context data in key "foo".
 *
 * The context Map can contain arbitrary data. The only assumption that
 * can be made by implementors is that if an Exception instance is given
 * to produce a stack trace, it MUST be in a key named "exception".
 *
 * See https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md
 * for the full interface specification.
 */
interface LoggerInterface extends ResetInterface {
  /**
   * System is unusable.
   */
  public function emergency(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Action must be taken immediately.
   *
   * Example: Entire website down, database unavailable, etc. This should
   * trigger the SMS alerts and wake you up.
   */
  public function alert(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Critical conditions.
   *
   * Example: Application component unavailable, unexpected exception.
   */
  public function critical(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Runtime errors that do not require immediate action but should typically
   * be logged and monitored.
   */
  public function error(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Exceptional occurrences that are not errors.
   *
   * Example: Use of deprecated APIs, poor use of an API, undesirable things
   * that are not necessarily wrong.
   */
  public function warning(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Normal but significant events.
   */
  public function notice(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Interesting events.
   *
   * Example: User logs in, SQL logs.
   */
  public function info(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Detailed debug information.
   */
  public function debug(
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;

  /**
   * Logs with an arbitrary level.
   */
  public function log(
    LogLevel $level,
    string $message,
    KeyedContainer<string, mixed> $context = dict[],
  ): void;
}
