<?hh // strict

namespace Nuxed\Contract\Log;

/**
 * Basic Implementation of LoggerAwareInterface.
 */
trait LoggerAwareTrait {
  require implements LoggerAwareInterface;

  /**
   * The logger instance.
   */
  protected ?LoggerInterface $logger;

  /**
   * Sets a logger.
   */
  public function setLogger(LoggerInterface $logger): void {
    $this->logger = $logger;
  }

  /**
   * Gets a logger.
   */
  protected function getLogger(): LoggerInterface {
    if (null === $this->logger) {
      $this->logger = new NullLogger();
    }
    return $this->logger;
  }
}
