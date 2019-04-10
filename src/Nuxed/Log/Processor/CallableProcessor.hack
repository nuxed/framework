namespace Nuxed\Log\Processor;

use type Nuxed\Log\Record;

class CallableProcessor implements ProcessorInterface {
  public function __construct(protected (function(Record): Record) $callable) {}

  public function process(Record $record): Record {
    $fun = $this->callable;

    return $fun($record);
  }
}
