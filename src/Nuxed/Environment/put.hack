namespace Nuxed\Environment;

/**
 * Store a variable in the environment.
 */
function put(string $name, string $value): void {
  list($name, $value) = parse($name.'='.$value);
  \putenv($name.'='.$value);
}
