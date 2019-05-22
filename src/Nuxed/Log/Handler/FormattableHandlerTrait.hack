namespace Nuxed\Log\Handler;

use namespace Nuxed\Log\Formatter;

trait FormattableHandlerTrait {
  require implements IFormattableHandler;

  protected ?Formatter\IFormatter $formatter = null;

  public function setFormatter(Formatter\IFormatter $formatter): this {
    $this->formatter = $formatter;

    return $this;
  }

  public function getFormatter(): Formatter\IFormatter {
    if (!$this->formatter) {
      $this->formatter = $this->getDefaultFormatter();
    }

    return $this->formatter;
  }

  /**
   * Gets the default formatter.
   *
   * Overwrite this if the LineFormatter is not a good default for your handler.
   */
  protected function getDefaultFormatter(): Formatter\IFormatter {
    return new Formatter\LineFormatter();
  }
}
