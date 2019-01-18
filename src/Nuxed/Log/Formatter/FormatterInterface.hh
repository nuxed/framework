<?hh // strict

namespace Nuxed\Log\Formatter;

use type Nuxed\Log\record;

interface FormatterInterface {
  public function format(record $record): record;
}
