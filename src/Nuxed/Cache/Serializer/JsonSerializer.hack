namespace Nuxed\Cache\Serializer;

use namespace Nuxed\Util\Json;

class JsonSerializer implements ISerializer {
  /**
   * Serialize a value.
   *
   * When serialization fails, no exception should be
   * thrown. Instead, this method should return null.
   */
  public function serialize(mixed $value): ?string {
    try {
      return Json\encode($value, false);
    } catch (Json\Exception\JsonEncodeException $e) {
      return null;
    }
  }

  /**
   * Unserializes a single value and throws and exception if anything goes wrong.
   */
  public function unserialize(string $value): dynamic {
    return Json\decode($value);
  }
}
