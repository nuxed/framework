namespace Nuxed\Http\Message\Response;

use namespace Nuxed\Http\Message\__Private;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Util;

/**
 * JSON response.
 *
 * Allows creating a response by passing data to the constructor; by default,
 * serializes the data to JSON, sets a status code of 200 and sets the
 * Content-Type header to application/json.
 */
final class JsonResponse extends Message\Response {
  private mixed $payload;

  /**
   * Create a JSON response with the given data.
   *
   * @param mixed $data Data to convert to JSON.
   * @param int $status Integer status code for the response; 200 by default.
   * @param KeyedContainer<string, Container<string>> $headers Container of headers to use at initialization.
   * @param int $encodingOptions JSON encoding options to use.
   */
  public function __construct(
    mixed $data,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
    ?int $encodingOptions = null,
  ) {
    $this->setPayload($data);
    $json = static::encode($data, $encodingOptions);
    $body = Message\stream($json);

    $headers =
      __Private\inject_content_type_in_headers('application/json', $headers);

    parent::__construct($status, $headers, $body);
  }

  public function getPayload(): mixed {
    return $this->payload;
  }

  public function withPayload(mixed $data): JsonResponse {
    $new = clone $this;
    $new->setPayload($data);
    return $this->updateBodyFor($new);
  }

  private function setPayload(mixed $data): void {
    if (\is_object($data)) {
      /* HH_IGNORE_ERROR[4110] $data is an object*/
      $data = clone $data;
    }

    $this->payload = $data;
  }

  /**
   * Update the response body for the given instance.
   *
   * @param this $toUpdate Instance to update.
   * @return this Returns a new instance with an updated body.
   */
  private function updateBodyFor(this $toUpdate): this {
    $json = static::encode($toUpdate->payload);
    $body = Message\stream($json);
    return $toUpdate->withBody($body);
  }

  /**
   * Default JSON encoding is performed with the following options, which
   * produces RFC4627-compliant JSON, capable of embedding into HTML.
   *
   * - JSON_HEX_TAG
   * - JSON_HEX_APOS
   * - JSON_HEX_AMP
   * - JSON_HEX_QUOT
   * - JSON_UNESCAPED_SLASHES
   */
  private static function encode(mixed $value, ?int $flags = null): string {
    return Util\Json::encode(
      $value,
      false,
      $flags ??
        \JSON_HEX_TAG |
          \JSON_HEX_AMP |
          \JSON_HEX_APOS |
          \JSON_HEX_QUOT |
          \JSON_UNESCAPED_SLASHES,
    );
  }
}
