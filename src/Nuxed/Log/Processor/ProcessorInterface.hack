namespace Nuxed\Log\Processor;

use type Nuxed\Log\record;

interface ProcessorInterface {
  public function process(record $record): record;
}
