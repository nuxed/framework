namespace Nuxed\Log\Processor;

use type Nuxed\Log\Record;

interface ProcessorInterface {
  public function process(Record $record): Record;
}
