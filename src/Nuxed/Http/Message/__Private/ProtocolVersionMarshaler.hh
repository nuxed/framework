<?hh // strict

namespace Nuxed\Http\Message\__Private;

use namespace HH\Lib\Regex;
use namespace Nuxed\Http\Message\Exception;

class ProtocolVersionMarshaler {
  public function marshal(KeyedContainer<string, mixed> $server): string {
    $protocol = (string)$server['SERVER_PROTOCOL'] ?? '1.1';

    if (
      !Regex\matches($protocol, re"#^(HTTP/)?(?P<version>[1-9]\d*(?:\.\d)?)$#")
    ) {
      throw Exception\UnrecognizedProtocolVersionException::forVersion(
        (string)$protocol,
      );
    }
    $matches = Regex\first_match(
      $protocol,
      re"#^(HTTP/)?(?P<version>[1-9]\d*(?:\.\d)?)$#",
    ) as nonnull;
    return $matches['version'];
  }
}
