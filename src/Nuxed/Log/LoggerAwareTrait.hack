namespace Nuxed\Log;

/**
 * Basic Implementation of ILoggerAware.
 */
trait LoggerAwareTrait implements ILoggerAware {
  /**
   * The logger instance.
   */
  protected ?ILogger $logger;

  /**
   * Sets a logger.
   */
  public function setLogger(ILogger $logger): void {
    $this->logger = $logger;
  }

  /**
   * Gets a logger.
   */
  protected function getLogger(): ILogger {
    if (null === $this->logger) {
      $this->logger = new NullLogger();
    }

    return $this->logger;
  }
}
