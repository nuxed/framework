namespace Nuxed\Log\Formatter;

use namespace Nuxed\Log;

interface IFormatter {
  public function format(Log\LogRecord $record): Log\LogRecord;
}
