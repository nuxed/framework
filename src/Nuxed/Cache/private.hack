namespace Nuxed\Cache\_Private;

use namespace HH\Lib\Str;
use namespace Nuxed\Cache\Exception;


/**
 * Validates a cache key.
 *
 * @throws InvalidArgumentException When $key is not valid
 */
function validate_key(string $key): void {
  if ('' === $key) {
    throw new Exception\InvalidArgumentException(
      'Cache key length must be greater than zero',
    );
  }

  foreach (vec['{', '}', '(', ')', '/', '\\', '@', ':'] as $c) {
    if (Str\contains($key, $c)) {
      throw new Exception\InvalidArgumentException(Str\format(
        'Cache key "%s" contains reserved characters {}()/\@:',
        $key,
      ));
    }
  }
}
