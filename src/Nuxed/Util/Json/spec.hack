namespace Nuxed\Util\Json;

use namespace Facebook\TypeSpec;

function spec<T>(
  string $json,
  TypeSpec\TypeSpec<T> $spec,
  bool $assert = false,
): T {
  $value = decode($json);
  if ($assert) {
    return $spec->assertType($value);
  }

  return $spec->coerceType($value);
}
