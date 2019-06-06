namespace Nuxed\Cache\Serializer;

/**
 * Serializes/Unserializes Hack values.
 *
 * Implementations of this interface MUST deal with errors carefully. They MUST
 * also deal with forward and backward compatibility at the storage format level.
 */
interface ISerializer {
  /**
   * Serialize a value.
   *
   * When serialization fails, no exception should be
   * thrown. Instead, this method should return null.
   */
  public function serialize(mixed $value): ?string;

  /**
   * Unserializes a single value and throws and exception if anything goes wrong.
   */
  public function unserialize(string $value): dynamic;
}
