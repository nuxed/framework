namespace Nuxed\Environment;

use namespace Nuxed\Io;
use namespace HH\Lib\Str;

/**
 * Load a .env file into the current environment.
 */
async function load(string $file, bool $override = false): Awaitable<void> {
  $file = new Io\File($file, false);
  $lines = await $file->lines();
  foreach ($lines as $line) {
    $trimmed = Str\trim($line);
    // ignore comments and empty lines
    if (Str\starts_with($trimmed, '#') || Str\is_empty($trimmed)) {
      continue;
    }

    list($name, $value) = parse($line);
    if ($value is nonnull) {
      $override ? put($name, $value) : add($name, $value);
    }
  }
}
