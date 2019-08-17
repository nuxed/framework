namespace Nuxed\Environment;

use namespace Nuxed\Filesystem;
use namespace HH\Asio;
use namespace HH\Lib\Str;

/**
 * Load a .env file into the current environment.
 */
async function load(string $file, bool $override = false): Awaitable<void> {
  $file = new Filesystem\File($file, false);
  $lines = await $file->lines();
  $variables = vec[];
  foreach ($lines as $line) {
    $variables[] = async {
      $trimmed = Str\trim($line);
      // ignore comments and empty lines
      if (Str\starts_with($trimmed, '#') || Str\is_empty($trimmed)) {
        return;
      }

      list($name, $value) = parse($line);
      if ($value is nonnull) {
        $override ? put($name, $value) : add($name, $value);
      }
    };
  }

  await Asio\v($variables);
}
