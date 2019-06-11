namespace Nuxed\Util\Json;

use namespace Facebook\TypeSpec;
use namespace Facebook\TypeAssert;

function spec<T>(
  string $json,
  TypeSpec\TypeSpec<T> $spec,
  bool $assert = false,
): T {
  $value = decode($json);
  try {
    if ($assert) {
      return $spec->assertType($value);
    }

    return $spec->coerceType($value);
  } catch (TypeAssert\TypeCoercionException $e) {
    throw new Exception\JsonDecodeException(
      $e->getMessage(),
      $e->getCode(),
      $e,
    );
  }
}
