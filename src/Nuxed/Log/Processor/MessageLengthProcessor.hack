namespace Nuxed\Log\Processor;

use namespace HH\Lib\Str;
use type Nuxed\Log\record;


class MessageLengthProcessor implements ProcessorInterface {
  public function __construct(protected int $maxLength = 1024) {}

  public function process(record $record): record {
    if (Str\length($record['message']) <= $this->maxLength) {
      return $record;
    }

    $record['message'] =
      Str\slice($record['message'], 0, $this->maxLength).'[...]';

    return $record;
  }
}
