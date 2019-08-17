namespace Nuxed\Environment;

use namespace HH\Lib\Str;

function is_debug(): bool {
  $debug = get('APP_DEBUG');
  if ($debug is null) {
    return false;
  }

  $debug = Str\lowercase($debug);
  if ($debug === 'false' || $debug === 'off') {
    return false;
  }

  return (bool)$debug;
}
