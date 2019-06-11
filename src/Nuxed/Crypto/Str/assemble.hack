namespace Nuxed\Crypto\Str;

use namespace HH\Lib\C;
use namespace HH\Lib\Str;

/**
 * Convert a container of integers to a string
 */
function assemble(Container<int> $chars): string {
  $args = vec($chars);
  foreach ($args as $i => $v) {
    $args[$i] = (int)($v & 0xff);
  }

  return \pack(Str\repeat('C', C\count($args)), ...$args);
}
