namespace Nuxed\Log\Handler;

use namespace Nuxed\Log\Formatter;

interface FormattableHandlerInterface extends HandlerInterface {
  /**
   * Sets the formatter.
   */
  public function setFormatter(Formatter\FormatterInterface $formatter): this;

  /**
   * Gets the formatter.
   */
  public function getFormatter(): Formatter\FormatterInterface;
}
