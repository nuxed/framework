namespace Nuxed\Http\Message\_Private;

use namespace HH\Lib\{C, Str};

/**
* Inject the provided Content-Type, if none is already present.
*/
function inject_content_type_in_headers(
  string $contentType,
  KeyedContainer<string, Container<string>> $headers,
): KeyedContainer<string, Container<string>> {
  $headers = dict($headers);

  $hasContentType = C\reduce_with_key(
    $headers,
    ($carry, $key, $item) ==>
      $carry ?: (Str\lowercase($key) === 'content-type'),
    false,
  );

  if (false === $hasContentType) {
    $headers['content-type'] = vec[
      $contentType,
    ];
  }

  return $headers;
}
