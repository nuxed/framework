namespace Nuxed\Util\Json;

function decode(string $json, bool $assoc = true): dynamic {
  try {
    $value = \json_decode(
      $json,
      $assoc,
      512,
      \JSON_BIGINT_AS_STRING | \JSON_FB_HACK_ARRAYS,
    );
    $error = \json_last_error();
    if (\JSON_ERROR_NONE !== $error) {
      throw new Exception\JsonDecodeException(Errors[$error], $error);
    }

    return $value;
  } catch (\Throwable $e) {
    throw new Exception\JsonDecodeException(
      $e->getMessage(),
      (int)$e->getCode(),
    );
  }
}
