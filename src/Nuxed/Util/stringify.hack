namespace Nuxed\Util;

use namespace HH\Lib\Str;
use type Nuxed\Util\Json;
use type DateTimeInterface;
use type Throwable;
use function is_object;
use function get_resource_type;
use function get_class;
use function gettype;

function stringify(mixed $value): string {
  if ($value is bool) {
    $value = ($value ? 'true' : 'false');
  } elseif ($value is string) {
    $value = '"'.$value.'"';
  } elseif ($value is num) {
    $value = $value is int ? $value : Str\format_number($value, 1);
  } elseif ($value is resource) {
    $value = 'resource['.get_resource_type($value).']';
  } elseif (null === $value) {
    $value = 'null';
  } elseif (is_object($value) && !$value is Container<_>) {
    if ($value is Throwable) {
      $value = get_class($value).
        '['.
        'message='.
        stringify($value->getMessage()).
        ', code='.
        stringify($value->getCode()).
        ', file='.
        stringify($value->getFile()).
        ', line='.
        stringify($value->getLine()).
        ', trace= '.
        stringify($value->getTrace()).
        ', previous='.
        stringify($value->getPrevious()).
        ']';
    } elseif ($value is DateTimeInterface) {
      $value = get_class($value).'['.$value->format("Y-m-d\TH:i:s.uP").']';
    } else {
      $value = 'object['.get_class($value).']';
    }
  } elseif ($value is Container<_>) {
    $value = Json::encode($value, false);
  } else {
    $value = '!'.gettype($value).Json::encode($value, false);
  }

  return (string)$value;
}
