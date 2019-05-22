namespace Nuxed\Util;

use namespace HH\Lib\Str;
use type Nuxed\Util\Json;

function stringify(mixed $value): string {
  if ($value is bool) {
    $value = ($value ? 'true' : 'false');
  } else if ($value is string) {
    $value = '"'.$value.'"';
  } else if ($value is num) {
    $value = $value is int ? $value : Str\format_number($value, 1);
  } else if ($value is resource) {
    $value = 'resource['.\get_resource_type($value).']';
  } else if (null === $value) {
    $value = 'null';
  } else if (\is_object($value) && !$value is Container<_>) {
    if ($value is \Throwable) {
      $value = \get_class($value).
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
    } else if ($value is \DateTimeInterface) {
      $value = \get_class($value).'['.$value->format("Y-m-d\TH:i:s.uP").']';
    } else {
      $value = 'object['.\get_class($value).']';
    }
  } else if ($value is Container<_>) {
    $value = Json::encode($value, false);
  } else {
    $value = '!'.\gettype($value).Json::encode($value, false);
  }

  return (string)$value;
}
