namespace Nuxed\Environment;

/**
 * Remove a variable from the environment.
 */
function forget(string $name): void {
  \putenv(_Private\Parser::parseName($name));
}
