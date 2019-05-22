namespace Nuxed\Log;

/**
 * Describes a logger-aware instance.
 */
interface ILoggerAware {
  /**
   * Sets a logger instance on the object.
   */
  public function setLogger(ILogger $logger): void;
}
