namespace Nuxed\Environment;

/**
 * add a variable to the environment if it doesn't exist.
 */
function add(string $name, string $value): void {
  if (!contains($name)) {
    put($name, $value);
  }
}
