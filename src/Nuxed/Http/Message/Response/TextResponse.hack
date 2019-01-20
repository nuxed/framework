namespace Nuxed\Http\Message\Response;

use namespace Nuxed\Http\Message\__Private;
use type Nuxed\Http\Message\Response;

/**
 * Plain text response.
 *
 * Allows creating a response by passing a string to the constructor;
 * by default, sets a status code of 200 and sets the Content-Type header to
 * text/plain.
 */
class TextResponse extends Response {
  /**
   * Create a plain text response.
   *
   * Produces a text response with a Content-Type of text/plain and a default
   * status of 200.
   */
  public function __construct(
    string $text,
    int $status = 200,
    KeyedContainer<string, Container<string>> $headers = dict[],
  ) {
    parent::__construct(
      $status,
      __Private\inject_content_type_in_headers(
        'text/plain; charset=utf-8',
        $headers,
      ),
      __Private\create_stream_from_string($text),
    );
  }
}
