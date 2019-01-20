namespace Nuxed\Log;

use type Nuxed\Contract\Log\LogLevel;
use type DateTime;

type record = shape(
  'level' => LogLevel,
  'message' => string,
  'context' => dict<string, mixed>,
  'time' => DateTime,
  'extra' => dict<string, mixed>,
  ?'formatted' => string,
  ...
);
