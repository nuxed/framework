namespace Nuxed\Log\Handler;

use namespace Nuxed\Log\Formatter;

trait FormattableHandlerTrait {
  require implements FormattableHandlerInterface;

  protected ?Formatter\FormatterInterface $formatter = null;

  public function setFormatter(Formatter\FormatterInterface $formatter): this {
    $this->formatter = $formatter;

    return $this;
  }

  public function getFormatter(): Formatter\FormatterInterface {
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
  protected function getDefaultFormatter(): Formatter\FormatterInterface {
    return new Formatter\LineFormatter();
  }
}
