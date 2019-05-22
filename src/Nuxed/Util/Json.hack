namespace Nuxed\Util;

use namespace Facebook\TypeAssert;
use type Nuxed\Util\Jsonable;

final abstract class Json {

  private static dict<int, string> $errors = dict[
    \JSON_ERROR_NONE => 'No error',
    \JSON_ERROR_DEPTH => 'Maximum stack depth exceeded',
    \JSON_ERROR_STATE_MISMATCH => 'State mismatch (invalid or malformed JSON)',
    \JSON_ERROR_CTRL_CHAR =>
      'Control character error, possibly incorrectly encoded',
    \JSON_ERROR_SYNTAX => 'Syntax error',
    \JSON_ERROR_UTF8 =>
      'Malformed UTF-8 characters, possibly incorrectly encoded',
    \JSON_ERROR_INF_OR_NAN => 'Inf and NaN cannot be JSON encoded',
    \JSON_ERROR_UNSUPPORTED_TYPE =>
      'A value of a type that cannot be encoded was given',
  ];

  public static function encode(
    mixed $value,
    bool $pretty = false,
    int $flags = 0,
  ): string {
    if ($value is Jsonable) {
      return $value->toJson($pretty);
    }

    $flags |= \JSON_UNESCAPED_UNICODE |
      \JSON_UNESCAPED_SLASHES |
      \JSON_PRESERVE_ZERO_FRACTION;
    if ($pretty) {
      $flags |= \JSON_PRETTY_PRINT;
    }

    $json = \json_encode($value, $flags);
    $error = \json_last_error();
    if (\JSON_ERROR_NONE !== $error) {
      throw new Exception\JsonEncodeException(static::$errors[$error], $error);
    }

    return $json;
  }

  public static function decode(string $json, bool $assoc = true): mixed {
    try {
      $value = \json_decode(
        $json,
        $assoc,
        512,
        \JSON_BIGINT_AS_STRING | \JSON_FB_HACK_ARRAYS,
      );
      $error = \json_last_error();
      if (\JSON_ERROR_NONE !== $error) {
        throw new Exception\JsonDecodeException(
          static::$errors[$error],
          $error,
        );
      }

      return $value;
    } catch (\Throwable $e) {
      throw new Exception\JsonDecodeException(
        $e->getMessage(),
        (int)$e->getCode(),
      );
    }
  }

  public static function structure<T>(
    string $json,
    TypeStructure<T> $structure,
  ): T {
    try {
      return TypeAssert\matches_type_structure(
        $structure,
        static::decode($json),
      );
    } catch (TypeAssert\IncorrectTypeException $e) {
      throw new Exception\JsonDecodeException(
        $e->getMessage(),
        $e->getCode(),
        $e,
      );
    }
  }
}
