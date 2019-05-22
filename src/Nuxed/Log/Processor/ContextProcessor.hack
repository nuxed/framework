namespace Nuxed\Log\Processor;

use namespace HH\Lib\Str;
use namespace Nuxed\Util;
use type Nuxed\Log\LogRecord;

class ContextProcessor implements IProcessor {
  public function process(LogRecord $record): LogRecord {
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
