<?hh // strict

namespace Nuxed\Contract\Log;

/**
 * Describes a logger-aware instance.
 */
interface LoggerAwareInterface {
  /**
   * Sets a logger instance on the object.
   */
  public function setLogger(LoggerInterface $logger): void;
}
