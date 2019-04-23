namespace Nuxed\Log\Processor;

use namespace HH\Lib\Str;
use namespace Nuxed\Util;
use type Nuxed\Log\Record;

class ContextProcessor implements ProcessorInterface {
  public function process(Record $record): Record {
    if (!Str\contains($record['message'], '}')) {
      return $record;
    }

    foreach ($record['context'] as $key => $value) {
      $placeholder = '{'.$key.'}';

      if (!Str\contains($record['message'], $placeholder)) {
        continue;
      }

      $record['message'] = Str\replace(
        $record['message'],
        $placeholder,
        Util\stringify($value),
      );
    }

    return $record;
  }
}
