namespace Nuxed\Http\Message\Request;

use namespace Nuxed\Util;
use namespace Nuxed\Http\Message;

function json(
  Message\Uri $uri,
  mixed $data,
  string $method = 'POST',
  KeyedContainer<string, Container<string>> $headers = dict[],
  string $version = '1.1',
): Message\Request {
  $flags = \JSON_HEX_TAG | \JSON_HEX_APOS | \JSON_HEX_AMP | \JSON_HEX_QUOT;
  $stream = Message\stream(Util\Json::encode($data, false, $flags));
  $headers = dict($headers);
  $headers['content-type'] ??= vec['application/json'];
  return Message\request($method, $uri, $headers, $stream, $version);
}
