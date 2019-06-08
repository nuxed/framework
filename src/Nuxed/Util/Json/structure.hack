namespace Nuxed\Util\Json;

use namespace Facebook\TypeAssert;

function structure<T>(string $json, TypeStructure<T> $structure): T {
  try {
    return TypeAssert\matches_type_structure($structure, decode($json));
  } catch (TypeAssert\IncorrectTypeException $e) {
    throw new Exception\JsonDecodeException(
      $e->getMessage(),
      $e->getCode(),
      $e,
    );
  }
}
