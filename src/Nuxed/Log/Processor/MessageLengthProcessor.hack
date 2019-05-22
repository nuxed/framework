namespace Nuxed\Log\Processor;

use namespace HH\Lib\Str;
use type Nuxed\Log\LogRecord;


class MessageLengthProcessor implements IProcessor {
  public function __construct(protected int $maxLength = 1024) {}

  public function process(LogRecord $record): LogRecord {
    if (Str\length($record['message']) <= $this->maxLength) {
      return $record;
    }

    $record['message'] = Str\slice($record['message'], 0, $this->maxLength).
      '[...]';

    return $record;
  }
}
