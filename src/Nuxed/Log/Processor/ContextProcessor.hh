<?hh

namespace Nuxed\Log\Processor;

use namespace HH\Lib\Str;
use namespace Nuxed\Lib;
use type Nuxed\Log\record;

class ContextProcessor implements ProcessorInterface {
  public function process(record $record): record {
    if (!Str\contains($record['message'], '}')) {
      return $record;
    }

    foreach ($record['context'] as $key => $value) {
      $placeholder = '{'.$key.'}';

      if (!Str\contains($record['message'], $placeholder)) {
        continue;
      }

      $record['message'] =
        Str\replace($record['message'], $placeholder, Lib\stringify($value));
    }

    return $record;
  }
}
