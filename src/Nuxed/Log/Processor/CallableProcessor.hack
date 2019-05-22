namespace Nuxed\Log\Processor;

use type Nuxed\Log\LogRecord;

class CallableProcessor implements IProcessor {
  public function __construct(
    protected (function(LogRecord): LogRecord) $callable,
  ) {}

  public function process(LogRecord $record): LogRecord {
    $fun = $this->callable;

    return $fun($record);
  }
}
