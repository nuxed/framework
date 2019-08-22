namespace Nuxed\Http\Message\Response;

use namespace Nuxed\Http\Message\_Private;
use namespace Nuxed\Http\Message;

/**
 * Create a plain text response.
 *
 * Produces a text response with a Content-Type of text/plain and a default
 * status of 200.
 */
function text(
  string $text,
  int $status = 200,
  KeyedContainer<string, Container<string>> $headers = dict[],
): Message\Response {
  return new Message\Response(
    $status,
    _Private\inject_content_type_in_headers(
      'text/plain; charset=utf-8',
      $headers,
    ),
    Message\stream($text),
  ) |> $$->withCharset('utf-8');
}

/**
 * Create an HTML response.
 *
 * Produces an HTML response with a Content-Type of text/html and a default
 * status of 200.
 */
function html(
  string $html,
  int $status = 200,
  KeyedContainer<string, Container<string>> $headers = dict[],
): Message\Response {
  return new Message\Response(
    $status,
    _Private\inject_content_type_in_headers(
      'text/html; charset=utf8',
      $headers,
    ),
    Message\stream($html),
  ) |> $$->withCharset('utf-8');
}

/**
 * Create an XML response.
 *
 * Produces an XML response with a Content-Type of application/xml and a default
 * status of 200.
 */
function xml(
  string $xml,
  int $status = 200,
  KeyedContainer<string, Container<string>> $headers = dict[],
): Message\Response {
  return new Message\Response(
    $status,
    _Private\inject_content_type_in_headers(
      'application/xml; charset=utf8',
      $headers,
    ),
    Message\stream($xml),
  ) |> $$->withCharset('utf-8');
}

/**
 * Create a redirect response.
 *
 * Produces a redirect response with a Location header and the given status
 * (302 by default).
 *
 * Note: this function overwrites the `location` $headers value.
 */
function redirect(
  Message\Uri $uri,
  int $status = 302,
  KeyedContainer<string, Container<string>> $headers = dict[],
): Message\Response {
  $headers = dict($headers);
  $headers['location'] = vec[
    $uri->toString(),
  ];
  return new Message\Response($status, $headers, Message\stream(''));
}

/**
 * Create an empty response with the given status code.
 *
 * @param int $status Status code for the response, if any.
 * @param KeyedContainer<string, Container<string>> $headers Container of headers to use at initialization.
 */
function empty(
  int $status = 204,
  KeyedContainer<string, Container<string>> $headers = dict[],
): Message\Response {
  $body = new Message\Stream(\fopen('php://temp', 'rb+'));
  return new Message\Response($status, $headers, $body);
}

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
 * @param KeyedContainer<string, mixed>             $data Data to convert to JSON object.
 * @param int                                       $status Integer status code for the response; 200 by default.
 * @param KeyedContainer<string, Container<string>> $headers Container of headers to use at initialization.
 * @param int                                       $encodingOptions JSON encoding options to use.
 */
function json(
  KeyedContainer<string, mixed> $data,
  int $status = 200,
  KeyedContainer<string, Container<string>> $headers = dict[],
  ?int $encodingOptions = null,
): JsonResponse {
  return new JsonResponse($data, $status, $headers, $encodingOptions);
}
