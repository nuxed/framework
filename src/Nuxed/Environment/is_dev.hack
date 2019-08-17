namespace Nuxed\Environment;

use namespace HH\Lib\Str;

function is_dev(): bool {
  return Str\starts_with(
    Str\lowercase(get('APP_ENV', 'prod') as string),
    'dev',
  );
}
