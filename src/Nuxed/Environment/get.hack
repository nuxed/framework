namespace Nuxed\Environment;

/**
 * Fetches a variable from the environment.
 */
function get(string $name, ?string $default = null): ?string {
  $value = \getenv(_Private\Parser::parseName($name));
  if ($value is bool) {
    return $default;
  }

  return _Private\Parser::parseValue($value);
}
