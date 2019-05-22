namespace Nuxed\Log\Processor;

use namespace Nuxed\Log;

interface IProcessor {
  public function process(Log\LogRecord $record): Log\LogRecord;
}
