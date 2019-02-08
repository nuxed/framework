<?hh // strict

namespace Nuxed\Util;

use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace HH\Lib\Vec;
use function levenshtein;

/**
 * @param string            $name  The original name of the item that does not exist
 * @param Container<string> $items a container of possible items
 */
<<__Memoize>>
function alternatives(
  string $name,
  Container<string> $items,
): Container<string> {
  $alternatives = dict[];
  foreach ($items as $item) {
    $lev = levenshtein($name, $item);
    if ($lev <= Str\length($name) / 3 || Str\contains($item, $name)) {
      $alternatives[$item] = $lev;
    }
  }

  return Vec\keys(Dict\sort($alternatives));
}
