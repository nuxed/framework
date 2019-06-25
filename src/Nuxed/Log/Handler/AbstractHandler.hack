namespace Nuxed\Log\Handler;

use namespace Nuxed\Log;
use type Nuxed\Contract\IReset;

abstract class AbstractHandler implements IFormattableHandler, IReset {
  use FormattableHandlerTrait;

  const dict<Log\LogLevel, int> LEVELS = dict[
    Log\LogLevel::DEBUG => 0,
    Log\LogLevel::INFO => 1,
    Log\LogLevel::NOTICE => 2,
    Log\LogLevel::WARNING => 3,
    Log\LogLevel::ERROR => 4,
    Log\LogLevel::CRITICAL => 5,
    Log\LogLevel::ALERT => 6,
    Log\LogLevel::EMERGENCY => 7,
  ];

  /**
   * @param Log\LogLevel   $level  The minimum logging level at which this handler will be triggered
   * @param bool       $bubble Whether the messages that are handled can bubble up the stack or not
   */
  public function __construct(
    public Log\LogLevel $level = Log\LogLevel::DEBUG,
    public bool $bubble = true,
  ) {}

  public function isHandling(Log\LogRecord $record): bool {
    $minimum = static::LEVELS[$this->level];
    $level = static::LEVELS[$record['level']];

    return $level >= $minimum;
  }

  public function handle(Log\LogRecord $record): bool {
    if (!$this->isHandling($record)) {
      return false;
    }

    $record = $this->getFormatter()->format($record);

    $this->write($record);

    return false === $this->bubble;
  }

  /**
   * Writes the record down to the log of the implementing handler
   */
  abstract protected function write(Log\LogRecord $record): void;

  public function close(): void {
  }

  public function reset(): void {
    if ($this->formatter is IReset) {
      $this->formatter->reset();
    }
  }
}
