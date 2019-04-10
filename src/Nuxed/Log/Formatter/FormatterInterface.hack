namespace Nuxed\Log\Formatter;

use namespace Nuxed\Log;

interface FormatterInterface {
  public function format(Log\Record $record): Log\Record;
}
