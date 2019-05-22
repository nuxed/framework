namespace Nuxed\Log\Handler;

use type Nuxed\Log\LogRecord;
use type Nuxed\Log\LogLevel;
use type Nuxed\Contract\IReset;

abstract class AbstractHandler implements IFormattableHandler, IReset {
  use FormattableHandlerTrait;

  const dict<LogLevel, int> LEVELS = dict[
    LogLevel::DEBUG => 0,
    LogLevel::INFO => 1,
    LogLevel::NOTICE => 2,
    LogLevel::WARNING => 3,
    LogLevel::ERROR => 4,
    LogLevel::CRITICAL => 5,
    LogLevel::ALERT => 6,
    LogLevel::EMERGENCY => 7,
  ];

  /**
   * @param LogLevel   $level  The minimum logging level at which this handler will be triggered
   * @param bool       $bubble Whether the messages that are handled can bubble up the stack or not
   */
  public function __construct(
    public LogLevel $level = LogLevel::DEBUG,
    public bool $bubble = true,
  ) {}

  public function isHandling(LogRecord $record): bool {
    $minimum = static::LEVELS[$this->level];
    $level = static::LEVELS[$record['level']];

    return $level >= $minimum;
  }

  public function handle(LogRecord $record): bool {
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
  abstract protected function write(LogRecord $record): void;

  public function close(): void {
  }

  public function reset(): void {
    if ($this->formatter is IReset) {
      $this->formatter->reset();
    }
  }
}
