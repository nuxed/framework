namespace Nuxed\Http\Message\_Private;

use namespace HH\Lib\Str;
use namespace HH\Lib\Regex;
use namespace Nuxed\Http\Message\Exception;

final class ProtocolVersionMarshaler {
  public function marshal(KeyedContainer<string, mixed> $server): string {
    $protocol = (string)$server['SERVER_PROTOCOL'] ?? '1.1';
    if (
      !Regex\matches($protocol, re"#^(HTTP/)?(?P<version>[1-9]\d*(?:\.\d)?)$#")
    ) {
      throw new Exception\UnrecognizedProtocolVersionException(
        Str\format('Unrecognized protocol version (%s).', $protocol),
      );
    }

    $matches = Regex\first_match(
      $protocol,
      re"#^(HTTP/)?(?P<version>[1-9]\d*(?:\.\d)?)$#",
    ) as nonnull;

    return $matches['version'];
  }
}
