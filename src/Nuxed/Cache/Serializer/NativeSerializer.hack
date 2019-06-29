namespace Nuxed\Cache\Serializer;

class NativeSerializer implements ISerializer {
  /**
   * Serialize a value.
   *
   * When serialization fails, no exception should be
   * thrown. Instead, this method should return null.
   */
  public function serialize(mixed $value): ?string {
    try {
      $val = @\serialize($value);
      if (false === $val) {
        return null;
      }

      return $val as string;
    } catch (\Throwable $e) {
      return null;
    }
  }

  /**
   * Unserializes a single value and throws and exception if anything goes wrong.
   */
  public function unserialize(string $value): dynamic {
    if ('b:0;' === $value) {
      return false;
    }

    if ('N;' === $value) {
      return null;
    }

    try {
      $unserialized = \unserialize($value);

      if (false !== $unserialized) {
        return $unserialized;
      }

      $error = \error_get_last();
      $message = (false === $error) || ($error['message'] is null)
        ? 'Failed to unserialize values'
        : $error['message'] as string;
      throw new \DomainException($message);
    } catch (\Error $e) {
      throw new \ErrorException(
        $e->getMessage(),
        (int)$e->getCode(),
        \E_ERROR,
        $e->getFile(),
        $e->getLine(),
      );
    }
  }
}
