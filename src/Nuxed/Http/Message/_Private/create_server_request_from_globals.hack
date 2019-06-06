namespace Nuxed\Http\Message\_Private;

use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\Dict;
use namespace HH\Lib\Experimental\IO;
use namespace Nuxed\Http\Message;
use namespace AzJezz\HttpNormalizer;

function create_server_request_from_globals(): Message\ServerRequest {
  /* HH_IGNORE_ERROR[2050] */
    $server = $_SERVER;
  /* HH_IGNORE_ERROR[2050] */
    $uploads = HttpNormalizer\normalize_files($_FILES);
  /* HH_IGNORE_ERROR[2050] */
    $cookies = HttpNormalizer\normalize($_COOKIE);
  $protocol = (new ProtocolVersionMarshaler())->marshal($server);
  $headers = (new HeadersMarshaler())->marshal($server);
  $uri = (new UriMarshaler())->marshal($server, $headers);
  $query = HttpNormalizer\parse($uri->getQuery());
  $method = Str\uppercase(($server['REQUEST_METHOD'] ?? 'GET') as string);
  $ct = $value ==> C\contains($headers['content-type'] ?? vec[], $value);

  if (
    'POST' === $method &&
    ($ct('application/x-www-form-urlencoded') || $ct('multipart/form-data'))
  ) {
    /* HH_IGNORE_ERROR[2050] */
      $body = HttpNormalizer\normalize($_POST);
  } else {
    $body = null;
  }

  $uploads = Vec\map(
    $uploads,
    ($value) ==> tuple(
      $value[0],
      new Message\UploadedFile(
        new Message\Stream(\fopen($value[1]['tmp_name'], 'rb')),
        $value[1]['size'],
        Message\UploadedFileError::assert($value[1]['error']),
        $value[1]['name'] ?? null,
        $value[1]['type'] ?? null,
      ),
    ),
  );

  return new Message\ServerRequest(
    $method,
    $uri,
    $headers,
    Message\stream(Asio\join(IO\request_input()->readAsync())),
    $protocol,
    $server,
  )
    |> $$->withCookieParams(
      Dict\pull($cookies, $value ==> $value[1], $value ==> $value[0]),
    )
    |> $$->withQueryParams(
      Dict\pull($query, $value ==> $value[1], $value ==> $value[0]),
    )
    |> $body is nonnull
      ? $$->withParsedBody(
        Dict\pull($body, $value ==> $value[1], $value ==> $value[0]),
      )
      : $$
    |> $$->withUploadedFiles(
      Dict\pull($uploads, $value ==> $value[1], $value ==> $value[0]),
    );
}
