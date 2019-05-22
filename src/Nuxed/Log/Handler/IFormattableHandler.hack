namespace Nuxed\Log\Handler;

use namespace Nuxed\Log\Formatter;

interface IFormattableHandler extends IHandler {
  /**
   * Sets the formatter.
   */
  public function setFormatter(Formatter\IFormatter $formatter): this;

  /**
   * Gets the formatter.
   */
  public function getFormatter(): Formatter\IFormatter;
}
