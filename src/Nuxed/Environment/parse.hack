namespace Nuxed\Environment;

/**
 * Parse the given environment variable entry into a name and value.
 */
function parse(string $entry): (string, ?string) {
  return _Private\Parser::parse($entry);
}
