namespace Nuxed\Log\Processor;

use namespace HH\Lib\Str;
use type Nuxed\Log\Record;


class MessageLengthProcessor implements ProcessorInterface {
  public function __construct(protected int $maxLength = 1024) {}

  public function process(Record $record): Record {
    if (Str\length($record['message']) <= $this->maxLength) {
      return $record;
    }

    $record['message'] =
      Str\slice($record['message'], 0, $this->maxLength).'[...]';

    return $record;
  }
}
