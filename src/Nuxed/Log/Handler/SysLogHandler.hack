namespace Nuxed\Log\Handler;

use namespace Nuxed\Log;
use namespace HH\Lib\Str;
use namespace Nuxed\Log\Exception;

class SysLogHandler extends AbstractHandler {
  /**
   * Translates Monolog log levels to syslog log priorities.
   */
  protected dict<Log\LogLevel, int> $Log\logLevels = dict[
    Log\LogLevel::DEBUG => \LOG_DEBUG,
    Log\LogLevel::INFO => \LOG_INFO,
    Log\LogLevel::NOTICE => \LOG_NOTICE,
    Log\LogLevel::WARNING => \LOG_WARNING,
    Log\LogLevel::ERROR => \LOG_ERR,
    Log\LogLevel::CRITICAL => \LOG_CRIT,
    Log\LogLevel::ALERT => \LOG_ALERT,
    Log\LogLevel::EMERGENCY => \LOG_EMERG,
  ];

  /**
   * @param Log\LogLevel   $level  The minimum logging level at which this handler will be triggered
   * @param bool       $bubble Whether the messages that are handled can bubble up the stack or not
   */
  public function __construct(
    protected string $ident,
    protected SysLogFacility $facility = SysLogFacility::USER,
    Log\LogLevel $level = Log\LogLevel::DEBUG,
    bool $bubble = true,
    protected int $options = \LOG_PID,
  ) {
    parent::__construct($level, $bubble);
  }
namespace
  <<__Override>>
  public$record): void {
    if (!\openlog($this->ident, $this->options, (int)$this->facility)) {
      throw new Exception\LogicException(Str\format(
        "Can't open syslog for ident %s and facility %d",
        $this->ident,
        (int)$this->facility,
      ));
    }

    \syslog(
      $this->Log\logLevels[$record['level']],
      $record['formatted'] ?? $record['message'],
    );
  }

  <<__Override>>
  public function close(): void {
    \closelog();
  }
}
