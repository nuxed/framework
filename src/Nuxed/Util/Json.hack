namespace Nuxed\Util;

use namespace Facebook\TypeAssert;
use type Nuxed\Contract\Util\Jsonable;
use type Throwable;
use function json_encode;
use function json_decode;
use function json_last_error;
use function json_last_error_msg;
use const JSON_PRESERVE_ZERO_FRACTION;
use const JSON_PRETTY_PRINT;
use const JSON_UNESCAPED_SLASHES;
use const JSON_UNESCAPED_UNICODE;
use const JSON_BIGINT_AS_STRING;
use const JSON_ERROR_NONE;
use const JSON_FB_HACK_ARRAYS;

final abstract class Json {
  public static function encode(mixed $value, bool $pretty = false): string {
    if ($value is Jsonable) {
      return $value->toJson($pretty);
    }

    $flags = JSON_UNESCAPED_UNICODE |
      JSON_UNESCAPED_SLASHES |
      JSON_PRESERVE_ZERO_FRACTION;
    if ($pretty) {
      $flags |= JSON_PRETTY_PRINT;
    }

    $json = json_encode($value, $flags);
    $error = json_last_error();
    if (JSON_ERROR_NONE !== $error) {
      throw new Exception\JsonEncodeException(json_last_error_msg(), $error);
    }

    return $json;
  }

  public static function decode(string $json, bool $assoc = true): mixed {
    try {
      $value = json_decode(
        $json,
        $assoc,
        512,
        JSON_BIGINT_AS_STRING | JSON_FB_HACK_ARRAYS,
      );
      $error = json_last_error();
      if (JSON_ERROR_NONE !== $error) {
        throw new Exception\JsonDecodeException(json_last_error_msg(), $error);
      }

      return $value;
    } catch (Throwable $e) {
      throw
        new Exception\JsonDecodeException($e->getMessage(), (int)$e->getCode());
    }
  }

  public static function structure<T>(
    string $json,
    TypeStructure<T> $structure,
  ): T {
    try {
      return
        TypeAssert\matches_type_structure($structure, static::decode($json));
    } catch (TypeAssert\IncorrectTypeException $e) {
      throw
        new Exception\JsonDecodeException($e->getMessage(), $e->getCode(), $e);
    }
  }
}
