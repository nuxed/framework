namespace Nuxed\Environment;

/**
 * Determine if a variable exists in the environment.
 */
function contains(string $name): bool {
  return get($name, null) is nonnull;
}
