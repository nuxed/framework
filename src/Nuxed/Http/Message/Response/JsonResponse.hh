<?hh // strict

namespace Nuxed\Http\Message\Response;

use namespace Nuxed\Http\Message\__Private;
use type Nuxed\Http\Message\Response;
use type Nuxed\Lib\Json;
use function is_object;
use const JSON_ERROR_NONE;

/**
 * JSON response.
 *
 * Allows creating a response by passing data to the constructor; by default,
 * serializes the data to JSON, sets a status code of 200 and sets the
 * Content-Type header to application/json.
 */
class JsonResponse extends Response {
  private mixed $payload;

  /**
   * Create a JSON response with the given data.
   *
   * Default JSON encoding is performed with the following options, which
   * produces RFC4627-compliant JSON, capable of embedding into HTML.
   *
   * - JSON_HEX_TAG
   * - JSON_HEX_APOS
   * - JSON_HEX_AMP
   * - JSON_HEX_QUOT
   * - JSON_UNESCAPED_SLASHES
   *
   * @param mixed $data Data to convert to JSON.
   * @param int $status Integer status code for the response; 200 by default.
   * @param KeyedContainer<string, Container<string>> $headers Map of headers to use at initialization.
   * @param int $encodingOptions JSON encoding options to use.
   * @throws Exception\InvalidArgumentException if unable to encode the $data to JSON.
   */
  public function __construct(
    mixed $data,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ) {
    $this->setPayload($data);
    $json = Json::encode($data);
    $body = __Private\create_stream_from_string($json);

    $headers =
      __Private\inject_content_type_in_headers('application/json', $headers);

    parent::__construct($status, $headers, $body);
  }

  /**
   * @return mixed
   */
  public function getPayload(): mixed {
    return $this->payload;
  }

  public function withPayload(mixed $data): JsonResponse {
    $new = clone $this;
    $new->setPayload($data);
    return $this->updateBodyFor($new);
  }

  /**
   * @param mixed $data
   */
  private function setPayload(mixed $data): void {
    if (is_object($data)) {
      /* HH_IGNORE_ERROR[4110] $data is an object*/
      $data = clone $data;
    }

    $this->payload = $data;
  }

  /**
   * Update the response body for the given instance.
   *
   * @param self $toUpdate Instance to update.
   * @return JsonResponse Returns a new instance with an updated body.
   */
  private function updateBodyFor(JsonResponse $toUpdate): JsonResponse {
    $json = Json::encode($toUpdate->payload);
    $body = __Private\create_stream_from_string($json);
    return $toUpdate->withBody($body);
  }
}
