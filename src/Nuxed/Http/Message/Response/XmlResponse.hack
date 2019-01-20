namespace Nuxed\Http\Message\Response;

use namespace Nuxed\Http\Message\__Private;
use type Nuxed\Http\Message\Response;

/**
 * XML response.
 *
 * Allows creating a response by passing an XML string to the constructor; by default,
 * sets a status code of 200 and sets the Content-Type header to application/xml.
 */
class XmlResponse extends Response {
  /**
   * Create an XML response.
   *
   * Produces an XML response with a Content-Type of application/xml and a default
   * status of 200.
   */
  public function __construct(
    string $xml,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ) {
    parent::__construct(
      $status,
      __Private\inject_content_type_in_headers(
        'application/xml; charset=utf8',
        $headers,
      ),
      __Private\create_stream_from_string($xml),
    );
  }
}
